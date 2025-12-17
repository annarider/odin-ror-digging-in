require "test_helper"

class UserProfilePhotoTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
  end

  # ============================================================================
  # COMPLETE USER FLOW TESTS - End-to-End Avatar Upload Journey
  # ============================================================================

  # Testing BEHAVIOR: User can complete full flow from profile to upload to viewing result
  # Testing OUTCOME: User sees their uploaded photo on profile after successful upload
  # This is the PRIMARY integration test - simulates real user behavior
  test "user can upload profile photo and see it displayed on their profile" do
    # Arrange - User logs in
    sign_in @user
    initial_avatar_attached = @user.avatar.attached?

    # Act - User visits their profile
    get user_path(@user)
    assert_response :success

    # User clicks "Edit Profile" button
    get edit_user_path(@user)
    assert_response :success
    assert_select "h1", text: "Edit Profile"
    assert_select "input[type='file'][name='user[avatar]']"

    # User uploads a photo
    avatar_file = fixture_file_upload("avatar.jpg", "image/jpeg")
    patch user_path(@user), params: {
      user: { avatar: avatar_file }
    }

    # Assert - User is redirected to their profile
    assert_redirected_to user_path(@user)
    follow_redirect!

    # Success message is displayed
    assert_match /Profile updated successfully!/, response.body

    # Avatar is now attached in the database
    @user.reload
    assert @user.avatar.attached?, "Avatar should be attached after upload"
    assert_not_equal initial_avatar_attached, @user.avatar.attached?

    # Profile page shows the uploaded avatar (not Gravatar)
    assert_response :success
    assert_select "img[alt*='profile picture']"
  end

  # Testing BEHAVIOR: User can update their name along with avatar in one action
  # Testing OUTCOME: Both name and avatar are updated, user sees both changes
  test "user can update name and avatar in single form submission" do
    # Arrange
    sign_in @user
    original_name = @user.name

    # Act - Visit edit page
    get edit_user_path(@user)
    assert_response :success

    # Submit form with both name and avatar
    avatar_file = fixture_file_upload("avatar.jpg", "image/jpeg")
    patch user_path(@user), params: {
      user: {
        name: "Garden Enthusiast",
        avatar: avatar_file
      }
    }

    # Assert - Redirected to profile with success
    assert_redirected_to user_path(@user)
    follow_redirect!
    assert_response :success

    # Both changes are reflected
    @user.reload
    assert_equal "Garden Enthusiast", @user.name
    assert_not_equal original_name, @user.name
    assert @user.avatar.attached?

    # New name appears on profile page
    assert_select "h1", text: "Garden Enthusiast"
  end

  # Testing BEHAVIOR: User can replace their existing avatar with a new one
  # Testing OUTCOME: Old avatar is replaced, new one is displayed
  test "user can replace existing avatar with new upload" do
    # Arrange - User already has an avatar
    sign_in @user
    first_avatar = fixture_file_upload("avatar.jpg", "image/jpeg")
    @user.avatar.attach(first_avatar)
    @user.save!
    first_blob_id = @user.avatar.blob.id
    assert @user.avatar.attached?

    # Act - Visit profile, should see edit button
    get user_path(@user)
    assert_response :success

    # Go to edit page
    get edit_user_path(@user)
    assert_response :success
    # Should show current avatar status
    assert_match /Custom photo uploaded/, response.body

    # Upload new avatar
    new_avatar = fixture_file_upload("avatar.jpg", "image/jpeg")
    patch user_path(@user), params: {
      user: { avatar: new_avatar }
    }

    # Assert - Redirected successfully
    assert_redirected_to user_path(@user)
    follow_redirect!

    # Avatar is replaced with new one
    @user.reload
    assert @user.avatar.attached?
    assert_not_equal first_blob_id, @user.avatar.blob.id
  end

  # Testing BEHAVIOR: Failed update shows errors and preserves user's input
  # Testing OUTCOME: Form redisplays with error messages, user doesn't lose their work
  test "user sees validation errors when update fails" do
    # Arrange
    sign_in @user
    get edit_user_path(@user)
    assert_response :success

    # Act - Submit invalid data (blank name)
    original_name = @user.name
    patch user_path(@user), params: {
      user: { name: "" }
    }

    # Assert - Returns to edit form (doesn't redirect)
    assert_response :unprocessable_entity
    # Should still be on edit form (testing outcome, not template name)
    assert_select "h1", text: "Edit Profile"

    # Error message is displayed (testing that user can see the error)
    assert_match /error/i, response.body
    assert_match /Name/, response.body
    assert_match /blank/, response.body

    # Data wasn't saved
    assert_equal original_name, @user.reload.name
  end

  # Testing BEHAVIOR: User cannot edit another user's profile (security)
  # Testing OUTCOME: Redirect with error message, no changes made
  test "user cannot access edit page for another user's profile" do
    # Arrange
    sign_in @user
    other_user = users(:two)
    other_user_name = other_user.name

    # Act - Try to access another user's edit page
    get edit_user_path(other_user)

    # Assert - Redirected away with error
    assert_redirected_to root_path
    follow_redirect!
    assert_match /You can only edit your own profile/, response.body

    # Try to force update via POST
    patch user_path(other_user), params: {
      user: { name: "Hacked Name" }
    }

    # Assert - Blocked and redirected
    assert_redirected_to root_path
    # Other user's data unchanged
    assert_equal other_user_name, other_user.reload.name
  end

  # Testing BEHAVIOR: Edit Profile button only appears on user's own profile
  # Testing OUTCOME: Button visible on own profile, hidden on others' profiles
  test "edit profile button appears only on user's own profile" do
    # Arrange
    sign_in @user
    other_user = users(:two)

    # Act & Assert - Own profile shows edit button
    get user_path(@user)
    assert_response :success
    assert_select "a[href='#{edit_user_path(@user)}']", text: /Edit Profile/

    # Other user's profile doesn't show edit button
    get user_path(other_user)
    assert_response :success
    assert_select "a[href='#{edit_user_path(other_user)}']", text: /Edit Profile/, count: 0
  end

  # Testing BEHAVIOR: Unauthenticated users cannot access edit functionality
  # Testing OUTCOME: Redirected to sign-in page
  test "unauthenticated user cannot access edit or update actions" do
    # Act - Try to access edit page without signing in
    get edit_user_path(@user)

    # Assert - Redirected to sign in
    assert_redirected_to new_user_session_path

    # Try to update without signing in
    patch user_path(@user), params: {
      user: { name: "New Name" }
    }

    # Assert - Redirected to sign in, no changes made
    assert_redirected_to new_user_session_path
    assert_not_equal "New Name", @user.reload.name
  end

  # Testing BEHAVIOR: Edit form shows current state accurately
  # Testing OUTCOME: User sees their current info and avatar status
  test "edit form displays current user information and avatar status" do
    # Arrange
    sign_in @user

    # Test without avatar
    get edit_user_path(@user)
    assert_response :success

    # Shows current name
    assert_select "input[name='user[name]'][value=?]", @user.name

    # Shows current profile picture
    assert_select "img[alt*='current profile picture']"

    # Shows "Using Gravatar default" message
    assert_match /Using Gravatar default/, response.body

    # Now attach an avatar
    @user.avatar.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "avatar.jpg")),
      filename: "avatar.jpg",
      content_type: "image/jpeg"
    )

    # Visit edit page again
    get edit_user_path(@user)
    assert_response :success

    # Now shows "Custom photo uploaded"
    assert_match /Custom photo uploaded/, response.body
    assert_match /avatar\.jpg/, response.body
  end

  # Testing BEHAVIOR: User can update name without affecting existing avatar
  # Testing OUTCOME: Avatar persists when only name is changed
  test "updating name alone preserves existing avatar" do
    # Arrange - User has an avatar
    sign_in @user
    avatar_file = fixture_file_upload("avatar.jpg", "image/jpeg")
    @user.avatar.attach(avatar_file)
    @user.save!
    original_blob_id = @user.avatar.blob.id

    # Act - Visit edit page
    get edit_user_path(@user)
    assert_response :success

    # Update only the name (no new avatar uploaded)
    patch user_path(@user), params: {
      user: { name: "Updated Garden Name" }
    }

    # Assert - Redirected successfully
    assert_redirected_to user_path(@user)
    follow_redirect!

    # Name is updated
    @user.reload
    assert_equal "Updated Garden Name", @user.name

    # Avatar still exists and unchanged
    assert @user.avatar.attached?
    assert_equal original_blob_id, @user.avatar.blob.id
  end

  # Testing BEHAVIOR: Profile page shows uploaded avatar to all users
  # Testing OUTCOME: Other users can see the custom avatar when visiting profile
  test "uploaded avatar is visible to other users viewing profile" do
    # Arrange - User one uploads an avatar
    sign_in @user
    avatar_file = fixture_file_upload("avatar.jpg", "image/jpeg")
    patch user_path(@user), params: {
      user: { avatar: avatar_file }
    }
    @user.reload
    assert @user.avatar.attached?

    # Sign out and sign in as different user
    sign_out @user
    other_user = users(:two)
    sign_in other_user

    # Act - Visit user one's profile
    get user_path(@user)
    assert_response :success

    # Assert - Profile picture is displayed (would be the uploaded avatar)
    # Testing OUTCOME: User can see the profile picture
    assert_select "img[alt*='profile picture']"
    # Should NOT show Edit Profile button (not their profile)
    assert_select "a[href='#{edit_user_path(@user)}']", text: /Edit Profile/, count: 0
  end
end
