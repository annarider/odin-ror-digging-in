require "test_helper"

# Integration tests for Posts Index Feed Feature
# Following Sandi Metz principles:
#   - Test from USER's perspective
#   - Test BEHAVIOR and OUTCOMES, not implementation
#   - Use REAL objects (no mocks for User, Post, FriendRequest)
class PostsFeedTest < ActionDispatch::IntegrationTest
  test "user sees their own posts and friends' posts in feed" do
    # Setup: Create users and establish friendship
    alice = User.create!(name: "Alice Gardener", email: "alice@garden.com", password: "password123")
    bob = User.create!(name: "Bob Planter", email: "bob@plants.com", password: "password123")

    # Alice and Bob become friends
    FriendRequest.create!(sender: alice, receiver: bob, status: "accepted")

    # Both create posts
    alice_post = alice.posts.create!(content: "Alice's tips on growing herbs")
    bob_post = bob.posts.create!(content: "Bob's guide to composting")

    # Alice logs in and views feed
    sign_in alice
    get posts_path

    # OUTCOME: Alice sees both her post and Bob's post
    assert_response :success
    assert_select "body", text: /Alice's tips on growing herbs/
    assert_select "body", text: /Bob's guide to composting/
  end

  test "user does not see posts from non-friends in feed" do
    # Setup: Three users - Alice, Bob (friends), and Charlie (stranger)
    alice = User.create!(name: "Alice", email: "alice@test.com", password: "password123")
    bob = User.create!(name: "Bob", email: "bob@test.com", password: "password123")
    charlie = User.create!(name: "Charlie", email: "charlie@test.com", password: "password123")

    # Alice and Bob are friends
    FriendRequest.create!(sender: alice, receiver: bob, status: "accepted")

    # All three create posts
    alice.posts.create!(content: "Alice talking about tulips")
    bob.posts.create!(content: "Bob discussing daisies")
    charlie.posts.create!(content: "Charlie explaining cacti")

    # Alice logs in and views feed
    sign_in alice
    get posts_path

    # OUTCOME: Alice sees her post and Bob's post, but NOT Charlie's
    assert_select "body", text: /tulips/
    assert_select "body", text: /daisies/
    assert_select "body", text: /cacti/, count: 0
  end

  test "feed shows posts in reverse chronological order" do
    # Setup: User creates posts at different times
    gardener = User.create!(name: "Gardener", email: "gardener@test.com", password: "password123")

    # Create posts with different timestamps
    old_post = gardener.posts.create!(content: "Week old post about seeds", created_at: 1.week.ago)
    mid_post = gardener.posts.create!(content: "Yesterday post about watering", created_at: 1.day.ago)
    new_post = gardener.posts.create!(content: "Recent post about harvesting", created_at: 1.hour.ago)

    sign_in gardener
    get posts_path

    # OUTCOME: Posts appear in reverse chronological order (newest first)
    response_body = response.body
    harvesting_pos = response_body.index("harvesting")
    watering_pos = response_body.index("watering")
    seeds_pos = response_body.index("seeds")

    assert harvesting_pos < watering_pos, "Newest post should appear first"
    assert watering_pos < seeds_pos, "Middle post should appear before oldest"
  end

  test "user can interact with friend's post from feed" do
    # Setup: Two friends
    user = User.create!(name: "User", email: "user@test.com", password: "password123")
    friend = User.create!(name: "Friend", email: "friend@test.com", password: "password123")
    FriendRequest.create!(sender: user, receiver: friend, status: "accepted")

    friend_post = friend.posts.create!(content: "Friend's amazing garden photo")

    sign_in user
    get posts_path

    # OUTCOME: User can see and interact with friend's post
    assert_select "body", text: /Friend's amazing garden photo/

    # User can like the friend's post from the feed
    assert_difference "Like.count", 1 do
      post post_likes_path(friend_post)
    end

    assert_redirected_to posts_path
    follow_redirect!

    # Verify like was added
    assert friend_post.reload.likes.exists?(user: user)
  end

  test "feed displays post metadata correctly" do
    # Setup: User with a post
    user = User.create!(name: "Test User", email: "test@example.com", password: "password123")
    test_post = user.posts.create!(content: "Post with engagement")

    # Add likes and comments
    commenter = User.create!(name: "Commenter", email: "commenter@test.com", password: "password123")
    test_post.comments.create!(content: "Nice post!", user: commenter)
    test_post.likes.create!(user: commenter)

    sign_in user
    get posts_path

    # OUTCOME: Feed shows post with correct like/comment counts
    assert_response :success
    assert_select "body", text: /1 like/
    assert_select "body", text: /1 comment/
  end

  test "user with no friends sees only their own posts" do
    # Setup: User with no friends
    loner = User.create!(name: "Solo Gardener", email: "solo@garden.com", password: "password123")
    loner.posts.create!(content: "My lonely garden post")

    # Create another user with a post (not friends)
    someone_else = User.create!(name: "Someone", email: "someone@test.com", password: "password123")
    someone_else.posts.create!(content: "Someone else's post")

    sign_in loner
    get posts_path

    # OUTCOME: Only sees own posts
    assert_select "body", text: /My lonely garden post/
    assert_select "body", text: /Someone else's post/, count: 0
  end

  test "bidirectional friendship shows posts correctly" do
    # Setup: Test that friendship works in both directions
    user_a = User.create!(name: "User A", email: "usera@test.com", password: "password123")
    user_b = User.create!(name: "User B", email: "userb@test.com", password: "password123")

    # User A sends friend request to User B
    FriendRequest.create!(sender: user_a, receiver: user_b, status: "accepted")

    user_a.posts.create!(content: "User A content about roses")
    user_b.posts.create!(content: "User B content about lilies")

    # OUTCOME: Both users see each other's posts
    sign_in user_a
    get posts_path
    assert_select "body", text: /roses/
    assert_select "body", text: /lilies/

    sign_out user_a

    sign_in user_b
    get posts_path
    assert_select "body", text: /roses/
    assert_select "body", text: /lilies/
  end

  test "feed includes link to create new post" do
    # Setup: User views feed
    user = User.create!(name: "Creative User", email: "creative@test.com", password: "password123")

    sign_in user
    get posts_path

    # OUTCOME: Feed has a link to create new post (text may vary with styling)
    assert_response :success
    assert_select "a[href=?]", new_post_path
  end

  test "pending friend request does not show friend's posts" do
    # Setup: Two users with pending (not accepted) friend request
    user = User.create!(name: "User", email: "user@pending.com", password: "password123")
    potential_friend = User.create!(name: "Potential Friend", email: "potential@test.com", password: "password123")

    # Pending friend request (not accepted)
    FriendRequest.create!(sender: user, receiver: potential_friend, status: "pending")

    potential_friend.posts.create!(content: "Potential friend's post about sunflowers")

    sign_in user
    get posts_path

    # OUTCOME: Pending friends' posts are NOT shown
    assert_select "body", text: /sunflowers/, count: 0
  end

  test "rejected friend request does not show posts" do
    # Setup: Two users with rejected friend request
    user = User.create!(name: "User", email: "user@rejected.com", password: "password123")
    rejected_user = User.create!(name: "Rejected", email: "rejected@test.com", password: "password123")

    # Rejected friend request
    FriendRequest.create!(sender: user, receiver: rejected_user, status: "rejected")

    rejected_user.posts.create!(content: "Rejected user's post")

    sign_in user
    get posts_path

    # OUTCOME: Rejected users' posts are NOT shown
    assert_select "body", text: /Rejected user's post/, count: 0
  end
end
