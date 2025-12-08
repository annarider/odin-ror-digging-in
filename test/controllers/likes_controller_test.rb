require "test_helper"

class LikesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @other_user = users(:two)
    @post = posts(:one)
    sign_in @user
  end

  # Create action tests
  test "should create like on post" do
    # Use post two which doesn't have a like from user one yet
    unliked_post = posts(:two)

    assert_difference("Like.count", 1) do
      post post_likes_path(unliked_post)
    end
    assert_redirected_to posts_path
    assert_equal "Successfully liked!", flash[:notice]
  end

  test "should create like on comment" do
    comment = @post.comments.create(content: "Test comment", user: @other_user)

    assert_difference("Like.count", 1) do
      post comment_likes_path(comment)
    end
    assert_redirected_to posts_path
    assert_equal "Successfully liked!", flash[:notice]
  end

  test "should not create duplicate like on same post" do
    # User one already has a like on post one from fixtures
    assert_no_difference("Like.count") do
      post post_likes_path(@post)
    end
    assert_redirected_to posts_path
    assert_equal "Couldn't add like.", flash[:alert]
  end

  # Destroy action tests
  test "should destroy own like" do
    # Use the like from fixtures
    like = likes(:one)

    assert_difference("Like.count", -1) do
      delete like_path(like)
    end
    assert_redirected_to posts_path
    assert_equal "Like removed.", flash[:notice]
  end

  test "should not allow destroying other user's like" do
    like = @post.likes.create(user: @other_user)

    assert_no_difference("Like.count") do
      delete like_path(like)
      assert_response :not_found
    end
  end
end
