require "test_helper"

class CommentTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @post = posts(:one)
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

  test "should work with Post as commentable" do
    @comment.commentable = @post
    assert @comment.valid?
    assert_equal "Post", @comment.commentable_type
  end

  test "should work with Comment as commentable (nested comments)" do
    parent_comment = Comment.create(content: "Parent comment", user: @user, commentable: @post)
    nested_comment = Comment.new(content: "Reply to comment", user: users(:two), commentable: parent_comment)
    assert nested_comment.valid?
    assert_equal "Comment", nested_comment.commentable_type
  end

  test "should allow multiple comments on the same post" do
    @comment.save
    another_comment = Comment.new(content: "Another great tip!", user: users(:two), commentable: @post)
    assert another_comment.valid?
    assert another_comment.save
  end

  test "should allow same user to comment multiple times on same post" do
    @comment.save
    another_comment = Comment.new(content: "Adding more thoughts...", user: @user, commentable: @post)
    assert another_comment.valid?
    assert another_comment.save
  end
end
