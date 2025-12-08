require "test_helper"

# Integration tests for Profile Pictures Feature
# Following Sandi Metz principles:
#   - Test from USER's perspective (what they see in the browser)
#   - Test BEHAVIOR and OUTCOMES (rendered HTML, not method calls)
#   - Use REAL objects (actual users, posts, friend requests from fixtures)
class ProfilePicturesTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @friend = users(:two)
  end

  test "user sees their profile picture on posts index page" do
    # Setup: User creates a post
    sign_in @user
    post = @user.posts.create!(content: "Testing my profile picture appears")

    # Act: User visits posts index
    get posts_path

    # Assert: User sees their profile picture displayed
    assert_response :success
    assert_select "img.profile-picture[alt=?]", "#{@user.name}'s profile picture"
    # Verify the image src contains gravatar URL with user's email hash
    gravatar_id = Digest::MD5.hexdigest(@user.email.downcase.strip)
    assert_select "img[src*='gravatar.com/avatar/#{gravatar_id}']"
  end

  test "user sees friend's profile picture on posts index page" do
    # Setup: Friend creates a post
    sign_in @user
    friend_post = @friend.posts.create!(content: "Friend's post content")

    # Act: User visits posts index
    get posts_path

    # Assert: User sees friend's profile picture
    assert_response :success
    assert_select "img.profile-picture[alt=?]", "#{@friend.name}'s profile picture"
    gravatar_id = Digest::MD5.hexdigest(@friend.email.downcase.strip)
    assert_select "img[src*='gravatar.com/avatar/#{gravatar_id}']"
  end

  test "user sees profile picture on individual post page" do
    # Setup: User has a post
    sign_in @user
    post = @user.posts.create!(content: "Individual post")

    # Act: User views their post
    get post_path(post)

    # Assert: Profile picture is displayed on the post
    assert_response :success
    assert_select "img.profile-picture[alt=?]", "#{@user.name}'s profile picture"
    gravatar_id = Digest::MD5.hexdigest(@user.email.downcase.strip)
    assert_select "img[src*='gravatar.com/avatar/#{gravatar_id}']"
  end

  test "user sees profile pictures on comments" do
    # Setup: User creates a post, friend comments on it
    sign_in @user
    post = @user.posts.create!(content: "Post with comments")
    comment = post.comments.create!(user: @friend, content: "Nice post!")

    # Act: User views the post with comments
    get post_path(post)

    # Assert: Friend's profile picture appears next to their comment
    assert_response :success
    assert_select "img.profile-picture-small[alt=?]", "#{@friend.name}'s profile picture"
    gravatar_id = Digest::MD5.hexdigest(@friend.email.downcase.strip)
    assert_select "img[src*='gravatar.com/avatar/#{gravatar_id}']"
  end

  test "multiple users show different profile pictures" do
    # Setup: Both users create posts
    sign_in @user
    @user.posts.create!(content: "User one post")
    @friend.posts.create!(content: "User two post")

    # Act: User views posts index
    get posts_path

    # Assert: Each user has their unique profile picture
    assert_response :success

    user_gravatar_id = Digest::MD5.hexdigest(@user.email.downcase.strip)
    friend_gravatar_id = Digest::MD5.hexdigest(@friend.email.downcase.strip)

    # Both gravatar URLs should be present
    assert_select "img[src*='gravatar.com/avatar/#{user_gravatar_id}']"
    assert_select "img[src*='gravatar.com/avatar/#{friend_gravatar_id}']"

    # And they should be different
    assert_not_equal user_gravatar_id, friend_gravatar_id
  end

  test "profile pictures maintain correct alt text for accessibility" do
    # Setup: User creates a post
    sign_in @user
    @user.posts.create!(content: "Accessibility test post")

    # Act: User visits posts index
    get posts_path

    # Assert: Profile picture has descriptive alt text
    assert_response :success
    assert_select "img.profile-picture[alt=?]", "#{@user.name}'s profile picture"
  end

  test "user sees sender profile picture on received friend requests" do
    # Setup: Friend sends user a friend request
    sign_in @user
    friend_request = FriendRequest.create!(sender: @friend, receiver: @user, status: "pending")

    # Act: User views friend requests page
    get friend_requests_path

    # Assert: Sender's profile picture is displayed
    assert_response :success
    assert_select "img.profile-picture[alt=?]", "#{@friend.name}'s profile picture"
    gravatar_id = Digest::MD5.hexdigest(@friend.email.downcase.strip)
    assert_select "img[src*='gravatar.com/avatar/#{gravatar_id}']"
  end

  test "user sees receiver profile picture on sent friend requests" do
    # Setup: User sends a friend request
    sign_in @user
    friend_request = FriendRequest.create!(sender: @user, receiver: @friend, status: "pending")

    # Act: User views friend requests page
    get friend_requests_path

    # Assert: Receiver's profile picture is displayed
    assert_response :success
    assert_select "img.profile-picture[alt=?]", "#{@friend.name}'s profile picture"
    gravatar_id = Digest::MD5.hexdigest(@friend.email.downcase.strip)
    assert_select "img[src*='gravatar.com/avatar/#{gravatar_id}']"
  end

  test "profile pictures use correct image sizes for different contexts" do
    # Setup: User creates a post with a comment
    sign_in @user
    post = @user.posts.create!(content: "Post for size testing")
    comment = post.comments.create!(user: @friend, content: "Comment")

    # Act: User views the post
    get post_path(post)

    # Assert: Post uses larger size (60), comment uses smaller size (40)
    assert_response :success

    # Post profile picture has larger size parameter
    assert_select "img.profile-picture[src*='s=60']"

    # Comment profile picture has smaller size parameter
    assert_select "img.profile-picture-small[src*='s=40']"
  end

  test "profile pictures work for users with mixed case emails" do
    # Setup: Create user with mixed case email (testing Gravatar requirement)
    mixed_case_user = User.create!(
      name: "Mixed Case User",
      email: "MiXeD@ExAmPlE.cOm",
      password: "password123",
      password_confirmation: "password123"
    )
    sign_in mixed_case_user
    mixed_case_user.posts.create!(content: "Testing mixed case email")

    # Act: User visits posts index
    get posts_path

    # Assert: Gravatar URL uses lowercase email hash
    assert_response :success
    lowercase_gravatar_id = Digest::MD5.hexdigest("mixed@example.com")
    assert_select "img[src*='gravatar.com/avatar/#{lowercase_gravatar_id}']"
  end
end
