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

  test "can be added to a post" do
    @like.save

    assert_includes @post.likes, @like
    assert_equal @post, @like.likeable
  end

  test "can be added to a comment" do
    comment = Comment.create(content: "Nice post!", user: @user, commentable: @post)
    like = Like.create(user: users(:two), likeable: comment)

    # Verify the like was created and associated with the comment
    assert like.persisted?
    assert_equal comment, like.likeable
    assert_equal 1, Like.where(likeable: comment).count
  end

  test "prevents same user from liking same item twice" do
    @like.save
    duplicate_like = @post.likes.build(user: @user)

    assert_not duplicate_like.save
    assert_equal 1, @post.likes.where(user: @user).count
  end

  test "allows different users to like same post" do
    @post.likes.create(user: @user)
    @post.likes.create(user: users(:two))

    assert_equal 2, @post.likes.count
  end

  test "allows same user to like different posts" do
    post1 = posts(:one)
    post2 = posts(:two)

    post1.likes.create(user: @user)
    post2.likes.create(user: @user)

    user_likes = Like.where(user: @user)
    assert_equal 2, user_likes.count
    assert_includes user_likes.map(&:likeable), post1
    assert_includes user_likes.map(&:likeable), post2
  end

  test "allows user to like both a post and a comment" do
    @post.likes.create(user: @user)
    comment = Comment.create(content: "Test", user: users(:two), commentable: @post)
    Like.create(user: @user, likeable: comment)

    user_likes = Like.where(user: @user)
    assert_equal 2, user_likes.count
  end
end
