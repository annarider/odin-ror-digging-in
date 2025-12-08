require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @post = posts(:one)
    sign_in @user
  end

  # Create action tests
  test "should create comment on post" do
    assert_difference("Comment.count", 1) do
      post post_comments_path(@post), params: { comment: { content: "Great gardening tip!" } }
    end
    assert_redirected_to post_path(@post)
    assert_equal "Comment posted.", flash[:notice]
  end

  test "should not create comment without content" do
    assert_no_difference("Comment.count") do
      post post_comments_path(@post), params: { comment: { content: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "created comment should belong to current user" do
    post post_comments_path(@post), params: { comment: { content: "Test comment" } }
    assert_equal @user.id, Comment.last.user_id
  end

  # Destroy action tests
  test "should destroy own comment" do
    comment = @post.comments.create(content: "My comment", user: @user)

    assert_difference("Comment.count", -1) do
      delete comment_path(comment)
    end
    assert_redirected_to post_path(@post)
    assert_equal "Comment removed.", flash[:notice]
  end

  test "should not allow destroying other user's comment" do
    comment = @post.comments.create(content: "Other's comment", user: @other_user)

    assert_no_difference("Comment.count") do
      delete comment_path(comment)
      assert_response :not_found
    end
  end
end
