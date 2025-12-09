require "test_helper"

class UserProfileTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @other_user = users(:two)
  end

  # Testing BEHAVIOR: Profile page displays user information
  # Testing OUTCOME: User can see name, email, member since date
  test "displays user profile information" do
    sign_in @user

    get user_path(@other_user)
    assert_response :success

    # Verify user information is displayed
    assert_select "h1", text: @other_user.name
    assert_match @other_user.email, response.body
    assert_match /Member since/, response.body
  end

  # Testing BEHAVIOR: Profile page shows profile picture
  # Testing OUTCOME: Profile picture image is present with correct alt text
  test "displays user profile picture" do
    sign_in @user

    get user_path(@other_user)

    # Verify profile picture is displayed
    assert_select "img.profile-picture-large[alt*='#{@other_user.name}']"
  end

  # Testing BEHAVIOR: Profile page shows user statistics
  # Testing OUTCOME: Displays post count and friend count
  test "displays user statistics" do
    sign_in @user

    # Delete existing fixtures to have clean count
    @other_user.posts.destroy_all

    # Create some posts for the user
    3.times { |i| Post.create!(user: @other_user, content: "Post #{i}") }

    get user_path(@other_user)

    # Verify statistics are displayed
    assert_select ".profile-stats"
    # Allow for any whitespace/newlines between number and text
    assert_match />3<.*>posts</m, response.body
    assert_match /friends?/, response.body
  end

  # Testing BEHAVIOR: Profile page lists user's posts
  # Testing OUTCOME: All user posts are visible with content
  test "displays all user posts" do
    sign_in @user

    # Create posts for the user
    post1 = Post.create!(user: @other_user, content: "I love growing tomatoes")
    post2 = Post.create!(user: @other_user, content: "My herb garden is thriving")

    get user_path(@other_user)

    # Verify posts are displayed
    assert_select ".user-posts"
    assert_select "body", text: /I love growing tomatoes/
    assert_select "body", text: /My herb garden is thriving/
  end

  # Testing BEHAVIOR: Profile shows posts in chronological order
  # Testing OUTCOME: Most recent posts appear first
  test "displays posts in reverse chronological order" do
    sign_in @user

    # Create posts with specific order
    old_post = Post.create!(
      user: @other_user,
      content: "OLD POST",
      created_at: 5.days.ago
    )
    new_post = Post.create!(
      user: @other_user,
      content: "NEW POST",
      created_at: 1.hour.ago
    )

    get user_path(@other_user)
    assert_response :success

    # Get the body content to check order
    body = response.body
    new_post_position = body.index("NEW POST")
    old_post_position = body.index("OLD POST")

    # NEW POST should appear before OLD POST in the HTML
    assert new_post_position < old_post_position, "Posts should be ordered newest first"
  end

  # Testing BEHAVIOR: Profile shows post engagement statistics
  # Testing OUTCOME: Displays like and comment counts for each post
  test "displays post statistics for likes and comments" do
    sign_in @user

    post = Post.create!(user: @other_user, content: "Great gardening day")

    # Create some engagement (can't have duplicate likes from same user)
    Like.create!(user: @user, likeable: post)
    Like.create!(user: @other_user, likeable: post)
    3.times { |i| Comment.create!(user: @user, content: "Comment #{i}", commentable: post) }

    get user_path(@other_user)

    # Verify statistics are shown
    assert_select "body", text: /2.*likes?/
    assert_select "body", text: /3.*comments?/
  end

  # Testing BEHAVIOR: Profile page has link to view full post
  # Testing OUTCOME: Each post has a "View Post" link
  test "provides links to view individual posts" do
    sign_in @user

    post = Post.create!(user: @other_user, content: "Check out my garden")

    get user_path(@other_user)

    # Verify link to post exists
    assert_select "a[href=?]", post_path(post), text: "View Post"
  end

  # Testing BEHAVIOR: Profile handles users with no posts
  # Testing OUTCOME: Shows appropriate message when no posts exist
  test "displays message when user has no posts" do
    sign_in @user

    # Create a user with no posts
    user_with_no_posts = User.create!(
      name: "New Gardener",
      email: "newbie@example.com",
      password: "password123"
    )

    get user_path(user_with_no_posts)

    assert_select "body", text: /No posts yet/
  end

  # Testing BEHAVIOR: Profile page has navigation back to posts feed
  # Testing OUTCOME: Link to all posts is present
  test "provides navigation back to all posts" do
    sign_in @user

    get user_path(@other_user)

    assert_select "a[href=?]", posts_path, text: /Back to All Posts/
  end

  # Testing BEHAVIOR: Profile page shows relative timestamps
  # Testing OUTCOME: Posts show "time ago" format
  test "displays relative timestamps for posts" do
    sign_in @user

    Post.create!(
      user: @other_user,
      content: "Recent post",
      created_at: 2.hours.ago
    )

    get user_path(@other_user)

    # Should contain "ago" text (from time_ago_in_words helper)
    assert_select "body", text: /ago/
  end

  # Testing BEHAVIOR: Only displays posts from the specific user
  # Testing OUTCOME: Other users' posts are not shown
  test "only shows posts belonging to the profile user" do
    sign_in @user

    # Create posts for different users
    target_user_post = Post.create!(user: @other_user, content: "Target user post")
    different_user_post = Post.create!(user: @user, content: "Different user post")

    get user_path(@other_user)

    # Should show target user's post
    assert_select "body", text: /Target user post/

    # Should NOT show different user's post
    assert_select "body", text: /Different user post/, count: 0
  end

  # Testing BEHAVIOR: Profile page shows correct singular/plural text
  # Testing OUTCOME: Uses "post" vs "posts" and "friend" vs "friends" correctly
  test "uses correct pluralization for statistics" do
    sign_in @user

    # Delete existing fixtures and create exactly 1 post
    @other_user.posts.destroy_all
    Post.create!(user: @other_user, content: "Only one post")

    get user_path(@other_user)

    # Should say "1 post" not "1 posts"
    # Allow for any whitespace/newlines between number and "post"
    assert_match />1<.*>post\s*</m, response.body
    # Make sure it doesn't say "posts" (plural)
    assert_select ".profile-stats", text: /1.*post[^s]/
  end

  # Testing BEHAVIOR: User can view their own profile
  # Testing OUTCOME: Successfully displays own profile information
  test "user can view their own profile" do
    sign_in @user

    # Create a post for self
    Post.create!(user: @user, content: "My own post")

    get user_path(@user)
    assert_response :success

    # Verify own information is displayed
    assert_select "h1", text: @user.name
    assert_select "body", text: /My own post/
  end
end
