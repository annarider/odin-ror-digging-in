require "test_helper"

class PostsFlowTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @other_user = users(:two)
  end

  test "user can create and view their own post" do
    # Sign in
    sign_in @user

    # Navigate to new post page
    get new_post_path
    assert_response :success

    # Create a new post
    assert_difference "Post.count", 1 do
      post posts_path, params: {
        post: {
          content: "I just planted some beautiful heirloom tomatoes in my garden!"
        }
      }
    end

    # Should redirect to the post show page
    created_post = Post.last
    assert_redirected_to post_path(created_post)
    follow_redirect!

    # Verify we can see the post content
    assert_response :success
    assert_select "body", text: /heirloom tomatoes/
  end

  test "user can edit their own post" do
    sign_in @user
    post = posts(:one)

    # Navigate to edit page
    get edit_post_path(post)
    assert_response :success

    # Update the post
    patch post_path(post), params: {
      post: { content: "Updated: My garden is thriving with organic vegetables" }
    }

    # Should redirect to posts index
    assert_redirected_to posts_path
    follow_redirect!

    # Verify the post was updated
    post.reload
    assert_equal "Updated: My garden is thriving with organic vegetables", post.content
  end

  test "user can delete their own post" do
    sign_in @user
    post = posts(:one)

    # Delete the post
    assert_difference "Post.count", -1 do
      delete post_path(post)
    end

    # Should redirect to posts index
    assert_redirected_to posts_path
    follow_redirect!
    assert_response :success
  end

  test "user cannot view another user's post" do
    sign_in @user
    other_user_post = posts(:two)

    get post_path(other_user_post)
    assert_response :not_found
  end

  test "user cannot edit another user's post" do
    sign_in @user
    other_user_post = posts(:two)

    get edit_post_path(other_user_post)
    assert_response :not_found
  end

  test "user cannot update another user's post" do
    sign_in @user
    other_user_post = posts(:two)
    original_content = other_user_post.content

    patch post_path(other_user_post), params: {
      post: { content: "Hacked content" }
    }
    assert_response :not_found

    other_user_post.reload
    assert_equal original_content, other_user_post.content
  end

  test "user cannot delete another user's post" do
    sign_in @user
    other_user_post = posts(:two)

    assert_no_difference "Post.count" do
      delete post_path(other_user_post)
      assert_response :not_found
    end
  end

  test "user must be signed in to access posts" do
    # Try to access posts without being signed in
    get posts_path
    assert_redirected_to new_user_session_path

    get new_post_path
    assert_redirected_to new_user_session_path

    post posts_path, params: { post: { content: "Test" } }
    assert_redirected_to new_user_session_path
  end

  test "complete post lifecycle with validations" do
    sign_in @user

    # Try to create an invalid post (no content)
    assert_no_difference "Post.count" do
      post posts_path, params: { post: { content: "" } }
    end
    assert_response :unprocessable_entity

    # Create a valid post
    assert_difference "Post.count", 1 do
      post posts_path, params: {
        post: { content: "My first post about companion planting" }
      }
    end

    created_post = Post.last
    assert_redirected_to post_path(created_post)

    # Try to update with invalid data
    patch post_path(created_post), params: { post: { content: "" } }
    assert_response :unprocessable_entity
    created_post.reload
    assert_equal "My first post about companion planting", created_post.content

    # Update with valid data
    patch post_path(created_post), params: {
      post: { content: "Updated: Companion planting saves space" }
    }
    assert_redirected_to posts_path
    created_post.reload
    assert_equal "Updated: Companion planting saves space", created_post.content
  end
end
