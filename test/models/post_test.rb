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

  test "should have many comments" do
    assert_respond_to @post, :comments
  end

  test "should have many likes" do
    assert_respond_to @post, :likes
  end

  test "should destroy associated comments when post is destroyed" do
    @post.save
    @post.comments.create(content: "Great post!", user: users(:two))
    assert_difference "Comment.count", -1 do
      @post.destroy
    end
  end

  test "should destroy associated likes when post is destroyed" do
    @post.save
    @post.likes.create(user: users(:two))
    assert_difference "Like.count", -1 do
      @post.destroy
    end
  end

  test "should allow a post with empty image" do
    @post.image = nil
    assert @post.valid?
  end
end
