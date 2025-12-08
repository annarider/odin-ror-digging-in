require "test_helper"

class ProfileNavigationTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @other_user = users(:two)
  end

  # Testing BEHAVIOR: User can navigate from posts index to user profile
  # Testing OUTCOME: Clicking user name takes you to their profile
  test "navigates from posts index to user profile by clicking name" do
    sign_in @user

    Post.create!(user: @other_user, content: "Check out my garden!")

    # Visit posts index
    get posts_path
    assert_response :success

    # Follow the link to the user's profile
    get user_path(@other_user)
    assert_response :success

    # Verify we're on the profile page
    assert_select "h1", text: @other_user.name
    assert_select ".user-profile"
  end

  # Testing BEHAVIOR: User can navigate from posts index to profile via profile picture
  # Testing OUTCOME: Clicking profile picture links to user profile
  test "posts index has clickable profile picture linking to user profile" do
    sign_in @user

    Post.create!(user: @other_user, content: "My post")

    get posts_path

    # Verify link exists wrapping the profile picture
    assert_select "a[href=?]", user_path(@other_user) do
      assert_select "img.profile-picture"
    end
  end

  # Testing BEHAVIOR: User can navigate from individual post to author profile
  # Testing OUTCOME: Post show page links to author profile
  test "navigates from post show page to author profile" do
    sign_in @user

    post = Post.create!(user: @other_user, content: "Beautiful roses blooming")

    # Visit post show page
    get post_path(post)
    assert_response :success

    # Verify link to author's profile exists
    assert_select "a[href=?]", user_path(@other_user), text: @other_user.name

    # Navigate to author's profile
    get user_path(@other_user)
    assert_response :success
    assert_select "h1", text: @other_user.name
  end

  # Testing BEHAVIOR: User can navigate from post comments to commenter profile
  # Testing OUTCOME: Comment author names link to their profiles
  test "navigates from post comments to commenter profile" do
    sign_in @user

    post = Post.create!(user: @other_user, content: "My garden post")
    comment = Comment.create!(
      user: @user,
      commentable: post,
      content: "Great post!"
    )

    # Visit post show page
    get post_path(post)
    assert_response :success

    # Verify link to commenter's profile exists in comments
    assert_select ".comment a[href=?]", user_path(@user), text: @user.name

    # Navigate to commenter's profile
    get user_path(@user)
    assert_response :success
    assert_select "h1", text: @user.name
  end

  # Testing BEHAVIOR: User can navigate from profile back to posts feed
  # Testing OUTCOME: Profile page has working back link
  test "navigates from profile back to posts index" do
    sign_in @user

    # Visit user profile
    get user_path(@other_user)
    assert_response :success

    # Verify back link exists
    assert_select "a[href=?]", posts_path, text: /Back to All Posts/

    # Follow back link
    get posts_path
    assert_response :success
    assert_select "h1", text: "Post Updates"
  end

  # Testing BEHAVIOR: User can navigate from profile post to full post view
  # Testing OUTCOME: Profile posts have links to individual post pages
  test "navigates from profile post preview to full post" do
    sign_in @user

    post = Post.create!(user: @other_user, content: "Tomato harvest")

    # Visit user profile
    get user_path(@other_user)
    assert_response :success

    # Verify link to full post exists
    assert_select "a[href=?]", post_path(post), text: "View Post"

    # Navigate to full post
    get post_path(post)
    assert_response :success
    assert_select "body", text: /Tomato harvest/
  end

  # Testing BEHAVIOR: Navigation maintains user context
  # Testing OUTCOME: Can navigate through multiple profiles
  test "navigates between different user profiles" do
    sign_in @user

    third_user = User.create!(
      name: "Third Gardener",
      email: "third@example.com",
      password: "password123"
    )

    # Visit first user's profile
    get user_path(@other_user)
    assert_response :success
    assert_select "h1", text: @other_user.name

    # Navigate to second user's profile
    get user_path(third_user)
    assert_response :success
    assert_select "h1", text: third_user.name

    # Navigate back to posts
    get posts_path
    assert_response :success

    # Navigate to own profile
    get user_path(@user)
    assert_response :success
    assert_select "h1", text: @user.name
  end

  # Testing BEHAVIOR: Complete user journey from feed to profile and back
  # Testing OUTCOME: User can complete full navigation flow
  test "complete navigation flow from feed through profile and back" do
    sign_in @user

    # Create posts for context
    post1 = Post.create!(user: @other_user, content: "First post")
    post2 = Post.create!(user: @other_user, content: "Second post")

    # Start at posts index
    get posts_path
    assert_response :success

    # Click on user name to go to profile
    get user_path(@other_user)
    assert_response :success
    assert_select ".user-posts", text: /First post/
    assert_select ".user-posts", text: /Second post/

    # Click on a post to view it in detail
    get post_path(post1)
    assert_response :success
    assert_select "body", text: /First post/

    # Click back to all posts
    get posts_path
    assert_response :success
    assert_select "h1", text: "Post Updates"
  end

  # Testing BEHAVIOR: Profile picture links work in comments section
  # Testing OUTCOME: Comment profile pictures link to user profiles
  test "comment profile pictures link to commenter profiles" do
    sign_in @user

    post = Post.create!(user: @other_user, content: "Garden update")
    Comment.create!(
      user: @user,
      commentable: post,
      content: "Nice garden!"
    )

    # Visit post show page
    get post_path(post)
    assert_response :success

    # Verify profile picture link exists in comment
    assert_select ".comment a[href=?]", user_path(@user) do
      assert_select "img.profile-picture-small"
    end
  end

  # Testing BEHAVIOR: Posts index shows author name as link
  # Testing OUTCOME: Multiple posts show correct author links
  test "posts index shows correct profile links for multiple users" do
    sign_in @user

    # Create posts from different users
    post1 = Post.create!(user: @user, content: "My post")
    post2 = Post.create!(user: @other_user, content: "Other post")

    get posts_path
    assert_response :success

    # Verify both profile links exist
    assert_select "a[href=?]", user_path(@user), text: @user.name
    assert_select "a[href=?]", user_path(@other_user), text: @other_user.name
  end

  # Testing BEHAVIOR: Navigation preserves authentication state
  # Testing OUTCOME: All navigation requires authentication
  test "navigation respects authentication requirements" do
    # Not signed in - should redirect
    get posts_path
    assert_redirected_to new_user_session_path

    get user_path(@user)
    assert_redirected_to new_user_session_path

    # Sign in and verify access
    sign_in @user

    get posts_path
    assert_response :success

    get user_path(@user)
    assert_response :success

    get user_path(@other_user)
    assert_response :success
  end
end
