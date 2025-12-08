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
  # Testing OUTCOME: Returns successful response with correct user
  test "shows user profile when authenticated" do
    sign_in @user

    get user_path(@other_user)
    assert_response :success
  end

  # Testing BEHAVIOR: Controller assigns correct user
  # Testing OUTCOME: Instance variable matches requested user
  test "assigns the requested user to @user" do
    sign_in @user

    get user_path(@other_user)
    assert_equal @other_user, assigns(:user)
  end

  # Testing BEHAVIOR: Controller loads user's posts
  # Testing OUTCOME: Posts are assigned and ordered by creation date descending
  test "assigns user's posts ordered by most recent first" do
    sign_in @user

    # Create posts with specific timestamps to test ordering
    old_post = Post.create!(
      user: @other_user,
      content: "Old post",
      created_at: 2.days.ago
    )
    new_post = Post.create!(
      user: @other_user,
      content: "New post",
      created_at: 1.hour.ago
    )
    middle_post = Post.create!(
      user: @other_user,
      content: "Middle post",
      created_at: 1.day.ago
    )

    get user_path(@other_user)

    assigned_posts = assigns(:posts)
    assert_equal 3, assigned_posts.size
    # Verify ordering: newest first
    assert_equal new_post.id, assigned_posts[0].id
    assert_equal middle_post.id, assigned_posts[1].id
    assert_equal old_post.id, assigned_posts[2].id
  end

  # Testing BEHAVIOR: Controller only loads posts for the specific user
  # Testing OUTCOME: Only the requested user's posts are included
  test "only assigns posts belonging to the requested user" do
    sign_in @user

    # Create posts for different users
    user_post = Post.create!(user: @other_user, content: "Other user's post")
    different_user_post = Post.create!(user: @user, content: "Different user's post")

    get user_path(@other_user)

    assigned_posts = assigns(:posts)
    assert_includes assigned_posts, user_post
    assert_not_includes assigned_posts, different_user_post
  end

  # Testing BEHAVIOR: Handles non-existent user gracefully
  # Testing OUTCOME: Raises RecordNotFound (Rails default behavior)
  test "raises error when user does not exist" do
    sign_in @user

    assert_raises(ActiveRecord::RecordNotFound) do
      get user_path(id: 99999)
    end
  end

  # Testing BEHAVIOR: Users can view their own profile
  # Testing OUTCOME: Successful response when viewing own profile
  test "user can view their own profile" do
    sign_in @user

    get user_path(@user)
    assert_response :success
    assert_equal @user, assigns(:user)
  end
end
