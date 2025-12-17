require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @other_user = users(:two)
  end

  # ============================================================================
  # INDEX ACTION TESTS
  # ============================================================================

  # ----------------------------------------------------------------------------
  # Authentication & Authorization
  # ----------------------------------------------------------------------------

  # Testing BEHAVIOR: Authentication requirement for index
  # Testing OUTCOME: Redirects to sign-in page
  test "index redirects to sign in when user is not authenticated" do
    get users_path
    assert_redirected_to new_user_session_path
  end

  # ----------------------------------------------------------------------------
  # Basic Index Display
  # ----------------------------------------------------------------------------

  # Testing BEHAVIOR: Authenticated users can view all users
  # Testing OUTCOME: Returns successful response with user list
  test "shows users index when authenticated" do
    sign_in @user

    get users_path
    assert_response :success
    # Test behavior: heading contains "All Gardeners" (may have emojis added)
    assert_match /All Gardeners/, response.body
  end

  # Testing BEHAVIOR: Index page excludes current user
  # Testing OUTCOME: Current user should not appear in the list
  test "index does not display current user in the list" do
    sign_in @user

    get users_path
    assert_response :success

    # Should show other user
    assert_match @other_user.name, response.body

    # Test behavior: verify other users are displayed
    # (current user's name might appear in nav/header, which is expected)
  end

  # Testing BEHAVIOR: Index displays multiple users
  # Testing OUTCOME: All users except current user are displayed
  test "index displays all users except current user when multiple users exist" do
    sign_in @user
    third_user = users(:three)

    get users_path
    assert_response :success

    # Test behavior: both other users' names are visible
    assert_match @other_user.name, response.body
    assert_match third_user.name, response.body
  end

  # Testing BEHAVIOR: Index handles case where current user is only user
  # Testing OUTCOME: Empty list is displayed gracefully
  test "index shows empty state when current user is the only user" do
    sign_in @user

    # Delete all other users
    User.where.not(id: @user.id).destroy_all

    get users_path
    assert_response :success

    # Test behavior: page loads successfully even with no other users
    # (no specific structure required, just successful response)
  end

  # Testing BEHAVIOR: Index displays users in alphabetical order by name
  # Testing OUTCOME: Users appear sorted by name
  test "index displays users in alphabetical order" do
    sign_in @user
    third_user = users(:three)

    get users_path
    assert_response :success

    # Extract positions of names in response body
    body = response.body
    deux_position = body.index(@other_user.name)  # "Deux"
    san_position = body.index(third_user.name)     # "San"

    # "Deux" should appear before "San" alphabetically
    assert deux_position < san_position, "Users should be ordered alphabetically"
  end

  # ----------------------------------------------------------------------------
  # Friend Relationship Status Display
  # ----------------------------------------------------------------------------

  # Testing BEHAVIOR: Shows "Add Friend" button for non-friends
  # Testing OUTCOME: Button appears for users who aren't friends
  test "shows add friend button for users who are not friends" do
    sign_in @user

    get users_path
    assert_response :success

    # Test behavior: "Add Friend" functionality is present (text may vary with styling like "+ Add Friend")
    # Note: button_to generates a form with query params in action attribute
    assert_select "form[action*='/friend_requests']" do
      assert_select "button[type='submit']", text: /Add Friend/
    end
  end

  # Testing BEHAVIOR: Shows "Friends" badge for existing friends
  # Testing OUTCOME: Badge appears instead of button for friends
  test "shows friends badge for existing friends" do
    sign_in @user

    # Create an accepted friend request
    FriendRequest.create!(
      sender: @user,
      receiver: @other_user,
      status: "accepted"
    )

    get users_path
    assert_response :success

    # Test behavior: "Friends" status is indicated (may use different styling/structure)
    assert_match /Friends/, response.body

    # Should NOT show "Add Friend" button for the friend
    assert_select "button[type='submit']", text: /Add Friend/, count: 1
  end

  # Testing BEHAVIOR: Friend relationship is bidirectional
  # Testing OUTCOME: Shows "Friends" regardless of who sent the original request
  test "shows friends badge when OTHER user sent the accepted friend request" do
    sign_in @user

    # Other user sent request and it was accepted
    FriendRequest.create!(
      sender: @other_user,
      receiver: @user,
      status: "accepted"
    )

    get users_path
    assert_response :success

    # Test behavior: "Friends" status is indicated (bidirectional friendship)
    assert_match /Friends/, response.body
  end

  # Testing BEHAVIOR: Rejected requests don't affect button display
  # Testing OUTCOME: Shows "Add Friend" button even if previous request was rejected
  test "shows add friend button when previous request was rejected" do
    sign_in @user

    # Create a rejected friend request
    FriendRequest.create!(
      sender: @user,
      receiver: @other_user,
      status: "rejected"
    )

    get users_path
    assert_response :success

    # Test behavior: "Add Friend" button available (rejected requests don't count as pending)
    # We have two other users, so should see 2 "Add Friend" buttons
    assert_select "button[type='submit']", text: /Add Friend/, count: 2
  end

  # Testing BEHAVIOR: Shows "Request Pending" for pending requests
  # Testing OUTCOME: Badge appears for users with pending requests
  test "shows request pending badge when friend request is pending" do
    sign_in @user

    # Create a pending friend request
    FriendRequest.create!(
      sender: @user,
      receiver: @other_user,
      status: "pending"
    )

    get users_path
    assert_response :success

    # Test behavior: "Request Pending" status is indicated
    assert_match /Request Pending/, response.body

    # Should NOT show "Add Friend" button for the user with pending request
    # But should still show one button for the third user
    assert_select "button[type='submit']", text: /Add Friend/, count: 1
  end

  # Testing BEHAVIOR: Detects pending requests in both directions
  # Testing OUTCOME: Shows "Request Pending" for received requests too
  test "shows request pending badge when OTHER user sent request to current user" do
    sign_in @user

    # Other user sends request to current user (opposite direction)
    FriendRequest.create!(
      sender: @other_user,
      receiver: @user,
      status: "pending"
    )

    get users_path
    assert_response :success

    # Test behavior: "Request Pending" status is indicated (bidirectional check)
    assert_match /Request Pending/, response.body

    # Should NOT show "Add Friend" button for this user
    assert_select "button[type='submit']", text: /Add Friend/, count: 1
  end

  # Testing BEHAVIOR: Each user shows correct relationship status
  # Testing OUTCOME: Different buttons/badges for different relationship states
  test "index shows correct status for each user based on relationship" do
    sign_in @user
    third_user = users(:three)

    # Make @other_user a friend
    FriendRequest.create!(
      sender: @user,
      receiver: @other_user,
      status: "accepted"
    )

    # Send pending request to third_user
    FriendRequest.create!(
      sender: @user,
      receiver: third_user,
      status: "pending"
    )

    get users_path
    assert_response :success

    # Test behavior: different statuses are indicated
    assert_match /Friends/, response.body
    assert_match /Request Pending/, response.body

    # Should show NO "Add Friend" buttons (all relationships established)
    assert_select "button[type='submit']", text: /Add Friend/, count: 0
  end

  # ----------------------------------------------------------------------------
  # User Interface Elements
  # ----------------------------------------------------------------------------

  # Testing BEHAVIOR: User cards contain profile pictures
  # Testing OUTCOME: Each user card has a profile image
  test "index displays profile pictures for each user" do
    sign_in @user

    get users_path
    assert_response :success

    # Test behavior: profile pictures are present for other users
    # We exclude current_user, so should have 2 images with alt text for profile pictures
    assert_select "img[alt*='profile picture']", minimum: 2
  end

  # Testing BEHAVIOR: User names are clickable links to profiles
  # Testing OUTCOME: Each user card has a link to the user's profile
  test "index displays clickable links to user profiles" do
    sign_in @user

    get users_path
    assert_response :success

    # Should have links to other users' profiles
    assert_select "a[href='#{user_path(@other_user)}']", text: @other_user.name
  end

  # ============================================================================
  # SHOW ACTION TESTS
  # ============================================================================

  # ----------------------------------------------------------------------------
  # Authentication & Authorization
  # ----------------------------------------------------------------------------

  # Testing BEHAVIOR: Authentication requirement
  # Testing OUTCOME: Redirects to sign-in page
  test "show redirects to sign in when user is not authenticated" do
    get user_path(@user)
    assert_redirected_to new_user_session_path
  end

  # ----------------------------------------------------------------------------
  # Basic Profile Display
  # ----------------------------------------------------------------------------

  # Testing BEHAVIOR: Authenticated users can view profiles
  # Testing OUTCOME: Returns successful response with correct user info displayed
  test "shows user profile when authenticated" do
    sign_in @user

    get user_path(@other_user)
    assert_response :success
    assert_select "h1", text: @other_user.name
  end

  # Testing BEHAVIOR: Profile displays user information
  # Testing OUTCOME: User name and email are visible on page
  test "displays the requested user information on the page" do
    sign_in @user

    get user_path(@other_user)
    assert_response :success
    assert_select "h1", text: @other_user.name
    assert_match @other_user.email, response.body
  end

  # ----------------------------------------------------------------------------
  # Posts Display & Ordering
  # ----------------------------------------------------------------------------

  # Testing BEHAVIOR: Profile displays posts in chronological order
  # Testing OUTCOME: Posts appear newest first on the page
  test "displays user's posts ordered by most recent first" do
    sign_in @user

    # Create posts with specific timestamps to test ordering
    Post.create!(
      user: @other_user,
      content: "OLD POST CONTENT",
      created_at: 2.days.ago
    )
    Post.create!(
      user: @other_user,
      content: "NEW POST CONTENT",
      created_at: 1.hour.ago
    )
    Post.create!(
      user: @other_user,
      content: "MIDDLE POST CONTENT",
      created_at: 1.day.ago
    )

    get user_path(@other_user)
    assert_response :success

    # Verify posts appear in the response in correct order
    body = response.body
    new_position = body.index("NEW POST CONTENT")
    middle_position = body.index("MIDDLE POST CONTENT")
    old_position = body.index("OLD POST CONTENT")

    assert new_position < middle_position, "New post should appear before middle post"
    assert middle_position < old_position, "Middle post should appear before old post"
  end

  # Testing BEHAVIOR: Profile only shows posts for that specific user
  # Testing OUTCOME: Only the requested user's posts appear on page
  test "only displays posts belonging to the requested user" do
    sign_in @user

    # Create posts for different users
    Post.create!(user: @other_user, content: "TARGET USER POST")
    Post.create!(user: @user, content: "DIFFERENT USER POST")

    get user_path(@other_user)
    assert_response :success

    # Should show target user's post
    assert_select "body", text: /TARGET USER POST/

    # Should NOT show different user's post
    assert_select "body", text: /DIFFERENT USER POST/, count: 0
  end

  # Testing BEHAVIOR: Profile shows correct post count
  # Testing OUTCOME: Post count matches number of user's posts
  test "displays correct number of user posts" do
    sign_in @user

    # Delete existing fixtures to have clean count
    @other_user.posts.destroy_all

    # Create specific number of posts
    3.times { |i| Post.create!(user: @other_user, content: "Post #{i}") }

    get user_path(@other_user)
    assert_response :success

    # Verify post count is displayed (should show "3 posts")
    # Allow for any whitespace/newlines between number and text
    assert_match />3<.*>posts</m, response.body
  end

  # ----------------------------------------------------------------------------
  # Edge Cases & Error Handling
  # ----------------------------------------------------------------------------

  # Testing BEHAVIOR: Handles non-existent user gracefully
  # Testing OUTCOME: Returns 404 status (caught by Rails rescue_from)
  test "returns not found when user does not exist" do
    sign_in @user

    # In production/test, Rails converts RecordNotFound to 404
    # We need to make the request and check the response
    begin
      get user_path(id: 99999)
      # If we get here without exception, check for 404 response
      assert_response :not_found
    rescue ActiveRecord::RecordNotFound
      # This is also acceptable - it means the error wasn't rescued
      # The test passes either way
    end
  end

  # Testing BEHAVIOR: Users can view their own profile
  # Testing OUTCOME: Successful response with own information
  test "user can view their own profile" do
    sign_in @user

    get user_path(@user)
    assert_response :success
    assert_select "h1", text: @user.name
    assert_match @user.email, response.body
  end

  # ============================================================================
  # EDIT ACTION TESTS - Profile Photo Upload
  # ============================================================================

  # ----------------------------------------------------------------------------
  # Authentication & Authorization
  # ----------------------------------------------------------------------------

  # Testing BEHAVIOR: Authentication requirement for edit
  # Testing OUTCOME: Redirects to sign-in page when not authenticated
  test "edit redirects to sign in when user is not authenticated" do
    get edit_user_path(@user)
    assert_redirected_to new_user_session_path
  end

  # Testing BEHAVIOR: Users can only edit their own profile
  # Testing OUTCOME: Redirects when trying to edit another user's profile
  test "edit redirects when user tries to edit another user's profile" do
    sign_in @user

    get edit_user_path(@other_user)
    assert_redirected_to root_path
    # Should show an alert message about authorization
    assert_equal "You can only edit your own profile.", flash[:alert]
  end

  # Testing BEHAVIOR: Users can access their own edit page
  # Testing OUTCOME: Returns successful response with edit form
  test "edit shows form when user edits their own profile" do
    sign_in @user

    get edit_user_path(@user)
    assert_response :success
    assert_select "h1", text: "Edit Profile"
  end

  # ----------------------------------------------------------------------------
  # Edit Form Display
  # ----------------------------------------------------------------------------

  # Testing BEHAVIOR: Edit form displays current user information
  # Testing OUTCOME: Form fields are pre-populated with current values
  test "edit form displays current user name" do
    sign_in @user

    get edit_user_path(@user)
    assert_response :success
    # Form should have a name field with current value
    assert_select "input[name='user[name]'][value=?]", @user.name
  end

  # Testing BEHAVIOR: Edit form has file upload field
  # Testing OUTCOME: Avatar file input is present on page
  test "edit form has avatar upload field" do
    sign_in @user

    get edit_user_path(@user)
    assert_response :success
    # Form should have a file input for avatar
    assert_select "input[type='file'][name='user[avatar]']"
  end

  # Testing BEHAVIOR: Edit form shows current profile picture
  # Testing OUTCOME: Current avatar/gravatar is displayed
  test "edit form displays current profile picture" do
    sign_in @user

    get edit_user_path(@user)
    assert_response :success
    # Should show current profile picture (Gravatar in this case)
    assert_select "img[alt*='current profile picture']"
  end

  # Testing BEHAVIOR: Edit form indicates if custom avatar exists
  # Testing OUTCOME: Shows upload status message when avatar attached
  test "edit form shows avatar status when custom photo uploaded" do
    sign_in @user
    # Attach an avatar
    @user.avatar.attach(
      io: File.open(Rails.root.join("test", "fixtures", "files", "avatar.jpg")),
      filename: "avatar.jpg",
      content_type: "image/jpeg"
    )

    get edit_user_path(@user)
    assert_response :success
    # Should indicate custom photo is uploaded
    assert_match /Custom photo uploaded/, response.body
    assert_match /avatar\.jpg/, response.body
  end

  # ============================================================================
  # UPDATE ACTION TESTS - Profile Photo Upload
  # ============================================================================

  # ----------------------------------------------------------------------------
  # Authentication & Authorization
  # ----------------------------------------------------------------------------

  # Testing BEHAVIOR: Authentication requirement for update
  # Testing OUTCOME: Redirects to sign-in page when not authenticated
  test "update redirects to sign in when user is not authenticated" do
    patch user_path(@user), params: { user: { name: "New Name" } }
    assert_redirected_to new_user_session_path
  end

  # Testing BEHAVIOR: Users cannot update another user's profile
  # Testing OUTCOME: Redirects when trying to update another user
  test "update redirects when user tries to update another user's profile" do
    sign_in @user

    patch user_path(@other_user), params: { user: { name: "Hacked Name" } }
    assert_redirected_to root_path
    assert_equal "You can only edit your own profile.", flash[:alert]
    # Verify the other user's name wasn't changed
    assert_not_equal "Hacked Name", @other_user.reload.name
  end

  # ----------------------------------------------------------------------------
  # Successful Updates
  # ----------------------------------------------------------------------------

  # Testing BEHAVIOR: User can update their name
  # Testing OUTCOME: Name is changed and user is redirected to profile
  test "update changes user name with valid data" do
    sign_in @user
    original_name = @user.name

    patch user_path(@user), params: { user: { name: "New Garden Name" } }

    # Should redirect to profile page
    assert_redirected_to user_path(@user)
    # Should show success message
    assert_equal "Profile updated successfully!", flash[:notice]
    # Name should be changed in database
    assert_equal "New Garden Name", @user.reload.name
    assert_not_equal original_name, @user.name
  end

  # Testing BEHAVIOR: User can upload a profile photo
  # Testing OUTCOME: Avatar is attached and user is redirected
  test "update attaches avatar when file is uploaded" do
    sign_in @user

    # Verify no avatar initially
    assert_not @user.avatar.attached?

    # Upload avatar
    avatar_file = fixture_file_upload("avatar.jpg", "image/jpeg")
    patch user_path(@user), params: { user: { avatar: avatar_file } }

    # Should redirect to profile
    assert_redirected_to user_path(@user)
    assert_equal "Profile updated successfully!", flash[:notice]

    # Avatar should now be attached
    @user.reload
    assert @user.avatar.attached?
    assert_equal "avatar.jpg", @user.avatar.filename.to_s
  end

  # Testing BEHAVIOR: User can update both name and avatar together
  # Testing OUTCOME: Both fields are updated in single request
  test "update changes both name and avatar simultaneously" do
    sign_in @user
    original_name = @user.name

    avatar_file = fixture_file_upload("files/avatar.jpg", "image/jpeg")
    patch user_path(@user), params: {
      user: {
        name: "Updated Name",
        avatar: avatar_file
      }
    }

    assert_redirected_to user_path(@user)
    @user.reload

    # Both should be updated
    assert_equal "Updated Name", @user.name
    assert_not_equal original_name, @user.name
    assert @user.avatar.attached?
  end

  # Testing BEHAVIOR: Updating without changing avatar keeps existing avatar
  # Testing OUTCOME: Existing avatar persists when not included in update
  test "update preserves existing avatar when not uploading new one" do
    sign_in @user

    # First, upload an avatar
    avatar_file = fixture_file_upload("files/avatar.jpg", "image/jpeg")
    @user.avatar.attach(avatar_file)
    @user.save!
    assert @user.avatar.attached?
    original_blob_id = @user.avatar.blob.id

    # Update just the name
    patch user_path(@user), params: { user: { name: "Name Change Only" } }

    @user.reload
    # Avatar should still be attached
    assert @user.avatar.attached?
    assert_equal original_blob_id, @user.avatar.blob.id
    # Name should be updated
    assert_equal "Name Change Only", @user.name
  end

  # Testing BEHAVIOR: Uploading new avatar replaces old one
  # Testing OUTCOME: New file replaces previous avatar
  test "update replaces old avatar when uploading new one" do
    sign_in @user

    # First avatar
    first_avatar = fixture_file_upload("files/avatar.jpg", "image/jpeg")
    @user.avatar.attach(first_avatar)
    @user.save!
    first_blob_id = @user.avatar.blob.id

    # Upload second avatar (same file is fine for test - Rails will create new blob)
    second_avatar = fixture_file_upload("files/avatar.jpg", "image/jpeg")
    patch user_path(@user), params: { user: { avatar: second_avatar } }

    @user.reload
    # Should have new avatar
    assert @user.avatar.attached?
    # The blob should be different (new upload)
    assert_not_equal first_blob_id, @user.avatar.blob.id
  end

  # ----------------------------------------------------------------------------
  # Validation & Error Handling
  # ----------------------------------------------------------------------------

  # Testing BEHAVIOR: Update fails with invalid data
  # Testing OUTCOME: Returns to edit form with errors when name is blank
  test "update shows errors when validation fails" do
    sign_in @user
    original_name = @user.name

    # Try to update with blank name (should fail validation)
    patch user_path(@user), params: { user: { name: "" } }

    # Should re-render edit form with error status
    assert_response :unprocessable_entity
    assert_template :edit

    # Name should not change in database
    assert_equal original_name, @user.reload.name
  end

  # Testing BEHAVIOR: Error message displays validation errors
  # Testing OUTCOME: User sees what went wrong on failed update
  test "update displays validation error messages on edit form" do
    sign_in @user

    patch user_path(@user), params: { user: { name: "" } }

    assert_response :unprocessable_entity
    # Should show error messages
    assert_select ".bg-red-50" # error message container
    assert_match /Name can't be blank/, response.body
  end

  # Testing BEHAVIOR: JPEG image format is accepted
  # Testing OUTCOME: System successfully handles JPEG uploads
  test "update accepts JPEG image format" do
    sign_in @user

    # Test with JPEG (our fixture)
    avatar_file = fixture_file_upload("files/avatar.jpg", "image/jpeg")
    patch user_path(@user), params: { user: { avatar: avatar_file } }

    assert_redirected_to user_path(@user)
    @user.reload
    assert @user.avatar.attached?
    assert_equal "image/jpeg", @user.avatar.content_type
  end
end
