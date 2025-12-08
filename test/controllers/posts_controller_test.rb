require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @post = posts(:one)
    sign_in @user
  end

  # Authentication tests
  test "should redirect to sign in when not authenticated" do
    sign_out @user
    get posts_url
    assert_redirected_to new_user_session_path
  end

  # Index action tests - Testing BEHAVIOR and OUTCOMES
  test "should get index when authenticated" do
    get posts_url
    assert_response :success
  end

  test "index shows current user's own posts" do
    # Create a post for the current user
    my_post = @user.posts.create!(content: "My gardening update about tomatoes")

    get posts_url

    # Verify OUTCOME: user can see their own post
    assert_select "body", text: /tomatoes/
  end

  test "index shows friends' posts" do
    # Setup: Create a friend and their post
    friend = User.create!(name: "Friend Gardener", email: "friend@example.com", password: "password123")
    friend_post = friend.posts.create!(content: "Friend's post about roses")

    # Setup: Make them friends by creating accepted friend request
    FriendRequest.create!(sender: @user, receiver: friend, status: "accepted")

    get posts_url

    # Verify OUTCOME: current user sees friend's post
    assert_select "body", text: /roses/
  end

  test "index does not show non-friend posts" do
    # Setup: Create a non-friend user and their post
    stranger = User.create!(name: "Stranger", email: "stranger@example.com", password: "password123")
    stranger_post = stranger.posts.create!(content: "Stranger's post about cucumbers")

    get posts_url

    # Verify OUTCOME: current user does NOT see stranger's post
    assert_select "body", text: /cucumbers/, count: 0
  end

  test "index does not show posts from pending friend requests" do
    # Setup: Create user with pending friend request
    pending_friend = User.create!(name: "Pending Friend", email: "pending@example.com", password: "password123")
    pending_post = pending_friend.posts.create!(content: "Pending friend's post about peppers")

    # Create pending (not accepted) friend request
    FriendRequest.create!(sender: @user, receiver: pending_friend, status: "pending")

    get posts_url

    # Verify OUTCOME: posts from pending friends are NOT shown
    assert_select "body", text: /peppers/, count: 0
  end

  test "index shows posts ordered by most recent first" do
    # Setup: Create posts at different times
    old_post = @user.posts.create!(content: "Old post about carrots", created_at: 2.days.ago)
    new_post = @user.posts.create!(content: "New post about lettuce", created_at: 1.hour.ago)

    get posts_url

    # Verify OUTCOME: posts are ordered by recency
    response_body = response.body
    lettuce_position = response_body.index("lettuce")
    carrots_position = response_body.index("carrots")

    assert lettuce_position < carrots_position, "Newer post should appear before older post"
  end

  test "index assigns correct posts to @posts instance variable" do
    # Setup: Create friend
    friend = User.create!(name: "Alice", email: "alice@example.com", password: "password123")
    FriendRequest.create!(sender: @user, receiver: friend, status: "accepted")

    # Create posts
    my_post = @user.posts.create!(content: "My content")
    friend_post = friend.posts.create!(content: "Friend content")

    get posts_url

    # Verify OUTCOME: @posts contains the right posts
    posts_in_response = assigns(:posts)
    assert_includes posts_in_response, my_post
    assert_includes posts_in_response, friend_post
    assert_equal 3, posts_in_response.count # my_post + friend_post + fixture post
  end

  # Show action tests
  test "should get show" do
    get post_url(@post)
    assert_response :success
  end

  test "should not show other user's post" do
    sign_in @other_user
    get post_url(@post)
    assert_response :not_found
  end

  # New action tests
  test "should get new" do
    get new_post_url
    assert_response :success
  end

  # Edit action tests
  test "should get edit" do
    get edit_post_url(@post)
    assert_response :success
  end

  test "should not allow editing other user's post" do
    sign_in @other_user
    get edit_post_url(@post)
    assert_response :not_found
  end

  # Create action tests
  test "should create post with valid attributes" do
    assert_difference("Post.count", 1) do
      post posts_url, params: { post: { content: "My new gardening post about roses!" } }
    end
    assert_redirected_to post_path(Post.last)
    assert_equal "New post created", flash[:notice]
  end

  test "should not create post without content" do
    assert_no_difference("Post.count") do
      post posts_url, params: { post: { content: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "created post should belong to current user" do
    post posts_url, params: { post: { content: "Another gardening tip" } }
    assert_equal @user.id, Post.last.user_id
  end

  # Update action tests
  test "should update post with valid attributes" do
    patch post_url(@post), params: { post: { content: "Updated content about perennials" } }
    assert_redirected_to posts_path
    @post.reload
    assert_equal "Updated content about perennials", @post.content
  end

  test "should not update post with invalid attributes" do
    original_content = @post.content
    patch post_url(@post), params: { post: { content: "" } }
    assert_response :unprocessable_entity
    @post.reload
    assert_equal original_content, @post.content
  end

  test "should not allow updating other user's post" do
    original_content = @post.content
    sign_in @other_user
    patch post_url(@post), params: { post: { content: "Hacked content" } }
    assert_response :not_found
    @post.reload
    assert_equal original_content, @post.content
  end

  # Destroy action tests
  test "should destroy post" do
    assert_difference("Post.count", -1) do
      delete post_url(@post)
    end
    assert_redirected_to posts_path
    assert_equal "Post deleted", flash[:notice]
  end

  test "should not allow destroying other user's post" do
    sign_in @other_user
    assert_no_difference("Post.count") do
      delete post_url(@post)
      assert_response :not_found
    end
  end

  test "destroying post also destroys its comments" do
    comment = @post.comments.create(content: "Test comment", user: @other_user)
    comment_id = comment.id

    delete post_url(@post)

    assert_nil Post.find_by(id: @post.id)
    assert_nil Comment.find_by(id: comment_id)
  end

  test "destroying post also destroys its likes" do
    like = @post.likes.create(user: @other_user)
    like_id = like.id

    delete post_url(@post)

    assert_nil Post.find_by(id: @post.id)
    assert_nil Like.find_by(id: like_id)
  end
end
