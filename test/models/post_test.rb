require "test_helper"

class PostTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @post = Post.new(content: "My first gardening post about tomatoes!", user: @user)
  end

  test "should be valid with valid attributes" do
    assert @post.valid?
  end

  test "should require content" do
    @post.content = nil
    assert_not @post.valid?
    assert_includes @post.errors[:content], "can't be blank"
  end

  test "should belong to a user" do
    @post.user = nil
    assert_not @post.valid?
  end

  test "can have comments added to it" do
    @post.save
    comment = @post.comments.create(content: "Great post!", user: users(:two))

    assert_includes @post.comments, comment
    assert_equal 1, @post.comments.count
  end

  test "can be liked by users" do
    @post.save
    like = @post.likes.create(user: users(:two))

    assert_includes @post.likes, like
    assert_equal 1, @post.likes.count
  end

  test "removes its comments when destroyed" do
    @post.save
    comment = @post.comments.create(content: "Great post!", user: users(:two))
    comment_id = comment.id

    @post.destroy

    assert_nil Comment.find_by(id: comment_id)
  end

  test "removes its likes when destroyed" do
    @post.save
    like = @post.likes.create(user: users(:two))
    like_id = like.id

    @post.destroy

    assert_nil Like.find_by(id: like_id)
  end

  test "should allow a post with empty image" do
    @post.image = nil
    assert @post.valid?
  end
end
