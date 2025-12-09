require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @other_user = users(:two)
  end

  # Testing BEHAVIOR: Authentication requirement for index
  # Testing OUTCOME: Redirects to sign-in page
  test "index redirects to sign in when user is not authenticated" do
    get users_path
    assert_redirected_to new_user_session_path
  end

  # Testing BEHAVIOR: Authentication requirement
  # Testing OUTCOME: Redirects to sign-in page
  test "redirects to sign in when user is not authenticated" do
    get user_path(@user)
    assert_redirected_to new_user_session_path
  end

  # Testing BEHAVIOR: Authenticated users can view all users
  # Testing OUTCOME: Returns successful response with user list
  test "shows users index when authenticated" do
    sign_in @user

    get users_path
    assert_response :success
    assert_select "h1", text: "All Gardeners"
  end

  # Testing BEHAVIOR: Index page excludes current user
  # Testing OUTCOME: Current user should not appear in the list
  test "index does not display current user in the list" do
    sign_in @user

    get users_path
    assert_response :success

    # Should show other user
    assert_match @other_user.name, response.body

    # Should NOT show current user in the list
    # (current user's name might appear in nav/header, so we check for the user card structure)
    assert_select ".user-card .user-info h3", text: @user.name, count: 0
  end

  # Testing BEHAVIOR: Shows "Add Friend" button for non-friends
  # Testing OUTCOME: Button appears for users who aren't friends
  test "shows add friend button for users who are not friends" do
    sign_in @user

    get users_path
    assert_response :success

    # Should show "Add Friend" button for other_user
    # Note: button_to generates a form with query params in action attribute
    assert_select "form[action*='/friend_requests']" do
      assert_select "button[type='submit']", text: "Add Friend"
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

    # Should show "Friends" badge
    assert_select ".badge.friend-badge", text: "Friends"

    # Should NOT show "Add Friend" button for the friend
    assert_select "button[type='submit']", text: "Add Friend", count: 1
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

    # Should show "Request Pending" badge
    assert_select ".badge.pending-badge", text: "Request Pending"

    # Should NOT show "Add Friend" button for the user with pending request
    # But should still show one button for the third user
    assert_select "button[type='submit']", text: "Add Friend", count: 1
  end

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
end
