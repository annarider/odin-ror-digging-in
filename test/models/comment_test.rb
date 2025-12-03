require "test_helper"

class CommentTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @post = Post.create(content: "Test post", user: @user)
    @comment = Comment.new(content: "Great gardening tips!", user: @user, commentable: @post)
  end

  test "should be valid with valid attributes" do
    assert @comment.valid?
  end

  test "should belong to a user" do
    @comment.user = nil
    assert_not @comment.valid?
  end

  test "should belong to a commentable (polymorphic)" do
    @comment.commentable = nil
    assert_not @comment.valid?
  end

  test "can be added to a post" do
    @comment.save

    assert_includes @post.comments, @comment
    assert_equal @post, @comment.commentable
  end

  test "can be replied to with another comment" do
    parent_comment = Comment.create(content: "Parent comment", user: @user, commentable: @post)
    reply = Comment.create(content: "Reply to comment", user: users(:two), commentable: parent_comment)

    # The reply should be associated with the parent comment
    assert_equal parent_comment, reply.commentable
    # Both comments should exist
    assert Comment.exists?(parent_comment.id)
    assert Comment.exists?(reply.id)
  end

  test "allows multiple users to comment on same post" do
    first_comment = @post.comments.create(content: "First comment", user: @user)
    second_comment = @post.comments.create(content: "Second comment", user: users(:two))

    assert_equal 2, @post.comments.count
    assert_includes @post.comments, first_comment
    assert_includes @post.comments, second_comment
  end

  test "allows same user to add multiple comments" do
    first_comment = @post.comments.create(content: "First thought", user: @user)
    second_comment = @post.comments.create(content: "Adding more thoughts...", user: @user)

    user_comments = @post.comments.where(user: @user)
    assert_equal 2, user_comments.count
    assert_includes user_comments, first_comment
    assert_includes user_comments, second_comment
  end
end
