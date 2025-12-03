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

  # Index action tests
  test "should get index" do
    get posts_url
    assert_response :success
  end

  test "index should only show current user's posts" do
    get posts_url
    assert_response :success
    # Check that the response includes the current user's post content
    assert_select "body", text: /#{@post.content}/
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
