require "test_helper"

class LikeTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @post = posts(:one)
    @like = Like.new(user: @user, likeable: @post)
  end

  test "should be valid with valid attributes" do
    assert @like.valid?
  end

  test "should belong to a user" do
    @like.user = nil
    assert_not @like.valid?
  end

  test "should belong to a likeable (polymorphic)" do
    @like.likeable = nil
    assert_not @like.valid?
  end

  test "should work with Post as likeable" do
    @like.likeable = @post
    assert @like.valid?
    assert_equal "Post", @like.likeable_type
  end

  test "should work with Comment as likeable" do
    comment = Comment.create(content: "Nice post!", user: @user, commentable: @post)
    like = Like.new(user: users(:two), likeable: comment)
    assert like.valid?
    assert_equal "Comment", like.likeable_type
  end

  test "should not allow same user to like same item twice" do
    @like.save
    duplicate_like = Like.new(user: @user, likeable: @post)
    assert_not duplicate_like.valid?
    assert_includes duplicate_like.errors[:user_id], "has already been taken"
  end

  test "should allow different users to like the same post" do
    @like.save
    another_like = Like.new(user: users(:two), likeable: @post)
    assert another_like.valid?
    assert another_like.save
  end

  test "should allow same user to like different posts" do
    @like.save
    another_post = posts(:two)
    another_like = Like.new(user: @user, likeable: another_post)
    assert another_like.valid?
    assert another_like.save
  end

  test "uniqueness validation should be scoped to likeable_type and likeable_id" do
    # User can like a post and a comment with same ID
    @like.save
    comment = Comment.create(content: "Test", user: users(:two), commentable: @post)
    # Even if by chance the comment has same ID as post (unlikely but possible in tests)
    comment_like = Like.new(user: @user, likeable: comment)
    assert comment_like.valid?
  end
end
