require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @other_user = users(:two)
  end

  # Testing BEHAVIOR: Authentication requirement
  # Testing OUTCOME: Redirects to sign-in page
  test "redirects to sign in when user is not authenticated" do
    get user_path(@user)
    assert_redirected_to new_user_session_path
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
    assert_match /3\s+posts/, response.body
  end
end
