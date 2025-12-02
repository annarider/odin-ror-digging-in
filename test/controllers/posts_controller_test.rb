require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get index" do
    get posts_url
    assert_response :success
  end

  test "should get show" do
    post = posts(:one)
    get post_url(post)
    assert_response :success
  end

  test "should get new" do
    get new_post_url
    assert_response :success
  end

  test "should get edit" do
    post = posts(:one)
    get edit_post_url(post)
    assert_response :success
  end
end
