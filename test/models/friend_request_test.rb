require "test_helper"

class FriendRequestTest < ActiveSupport::TestCase
  # Helper to create users quickly
  def create_user(name:, email:)
    User.create!(
      name: name,
      email: email,
      password: "password123",
      password_confirmation: "password123"
    )
  end

  # ===================
  # Association Tests
  # ===================

  test "belongs to sender" do
    alice = create_user(name: "Alice", email: "alice@example.com")
    bob = create_user(name: "Bob", email: "bob@example.com")

    friend_request = FriendRequest.create!(
      sender: alice,
      receiver: bob,
      status: "pending"
    )

    assert_equal alice, friend_request.sender
  end

  test "belongs to receiver" do
    alice = create_user(name: "Alice", email: "alice@example.com")
    bob = create_user(name: "Bob", email: "bob@example.com")

    friend_request = FriendRequest.create!(
      sender: alice,
      receiver: bob,
      status: "pending"
    )

    assert_equal bob, friend_request.receiver
  end

  # ===================
  # Validation Tests
  # ===================

  test "is valid with valid attributes" do
    alice = create_user(name: "Alice", email: "alice@example.com")
    bob = create_user(name: "Bob", email: "bob@example.com")

    friend_request = FriendRequest.new(
      sender: alice,
      receiver: bob,
      status: "pending"
    )

    assert friend_request.valid?
  end

  test "is invalid without a sender" do
    bob = create_user(name: "Bob", email: "bob@example.com")

    friend_request = FriendRequest.new(
      receiver: bob,
      status: "pending"
    )

    assert_not friend_request.valid?
    assert_includes friend_request.errors[:sender], "must exist"
  end

  test "is invalid without a receiver" do
    alice = create_user(name: "Alice", email: "alice@example.com")

    friend_request = FriendRequest.new(
      sender: alice,
      status: "pending"
    )

    assert_not friend_request.valid?
    assert_includes friend_request.errors[:receiver], "must exist"
  end

  test "is invalid with invalid status" do
    alice = create_user(name: "Alice", email: "alice@example.com")
    bob = create_user(name: "Bob", email: "bob@example.com")

    friend_request = FriendRequest.new(
      sender: alice,
      receiver: bob,
      status: "invalid_status"
    )

    assert_not friend_request.valid?
    assert_includes friend_request.errors[:status], "is not included in the list"
  end

  test "status pending is valid" do
    alice = create_user(name: "Alice", email: "alice@example.com")
    bob = create_user(name: "Bob", email: "bob@example.com")

    friend_request = FriendRequest.new(sender: alice, receiver: bob, status: "pending")
    assert friend_request.valid?
  end

  test "status accepted is valid" do
    alice = create_user(name: "Alice", email: "alice@example.com")
    bob = create_user(name: "Bob", email: "bob@example.com")

    friend_request = FriendRequest.new(sender: alice, receiver: bob, status: "accepted")
    assert friend_request.valid?
  end

  test "status rejected is valid" do
    alice = create_user(name: "Alice", email: "alice@example.com")
    bob = create_user(name: "Bob", email: "bob@example.com")

    friend_request = FriendRequest.new(sender: alice, receiver: bob, status: "rejected")
    assert friend_request.valid?
  end

  test "cannot send friend request to yourself" do
    alice = create_user(name: "Alice", email: "alice@example.com")

    friend_request = FriendRequest.new(
      sender: alice,
      receiver: alice,
      status: "pending"
    )

    assert_not friend_request.valid?
    assert_includes friend_request.errors[:sender_id], "cannot send friend request to yourself"
  end

  test "cannot send duplicate friend request" do
    alice = create_user(name: "Alice", email: "alice@example.com")
    bob = create_user(name: "Bob", email: "bob@example.com")

    FriendRequest.create!(sender: alice, receiver: bob, status: "pending")

    duplicate_request = FriendRequest.new(
      sender: alice,
      receiver: bob,
      status: "pending"
    )

    assert_not duplicate_request.valid?
    assert_includes duplicate_request.errors[:sender_id], "already sent a friend request"
  end

  test "cannot send request if already friends" do
    alice = create_user(name: "Alice", email: "alice@example.com")
    bob = create_user(name: "Bob", email: "bob@example.com")

    # Create accepted friendship
    FriendRequest.create!(sender: alice, receiver: bob, status: "accepted")

    # Try to create another request
    new_request = FriendRequest.new(
      sender: bob,
      receiver: alice,
      status: "pending"
    )

    assert_not new_request.valid?
    assert_includes new_request.errors[:base], "already friends with this user"
  end

  # ===================
  # Scope Tests
  # ===================

  test "pending scope returns only pending requests" do
    alice = create_user(name: "Alice", email: "alice@example.com")
    bob = create_user(name: "Bob", email: "bob@example.com")
    charlie = create_user(name: "Charlie", email: "charlie@example.com")

    pending_request = FriendRequest.create!(sender: alice, receiver: bob, status: "pending")
    FriendRequest.create!(sender: alice, receiver: charlie, status: "accepted")

    pending_requests = FriendRequest.pending

    assert_includes pending_requests, pending_request
    assert_equal 1, pending_requests.count
  end

  test "accepted scope returns only accepted requests" do
    alice = create_user(name: "Alice", email: "alice@example.com")
    bob = create_user(name: "Bob", email: "bob@example.com")
    charlie = create_user(name: "Charlie", email: "charlie@example.com")

    FriendRequest.create!(sender: alice, receiver: bob, status: "pending")
    accepted_request = FriendRequest.create!(sender: alice, receiver: charlie, status: "accepted")

    accepted_requests = FriendRequest.accepted

    assert_includes accepted_requests, accepted_request
    assert_equal 1, accepted_requests.count
  end

  test "rejected scope returns only rejected requests" do
    alice = create_user(name: "Alice", email: "alice@example.com")
    bob = create_user(name: "Bob", email: "bob@example.com")
    charlie = create_user(name: "Charlie", email: "charlie@example.com")

    FriendRequest.create!(sender: alice, receiver: bob, status: "pending")
    rejected_request = FriendRequest.create!(sender: alice, receiver: charlie, status: "rejected")

    rejected_requests = FriendRequest.rejected

    assert_includes rejected_requests, rejected_request
    assert_equal 1, rejected_requests.count
  end

  # ===================
  # Instance Method Tests
  # ===================

  test "accept! changes status to accepted" do
    alice = create_user(name: "Alice", email: "alice@example.com")
    bob = create_user(name: "Bob", email: "bob@example.com")

    friend_request = FriendRequest.create!(
      sender: alice,
      receiver: bob,
      status: "pending"
    )

    friend_request.accept!

    assert_equal "accepted", friend_request.reload.status
  end

  test "reject! changes status to rejected" do
    alice = create_user(name: "Alice", email: "alice@example.com")
    bob = create_user(name: "Bob", email: "bob@example.com")

    friend_request = FriendRequest.create!(
      sender: alice,
      receiver: bob,
      status: "pending"
    )

    friend_request.reject!

    assert_equal "rejected", friend_request.reload.status
  end

  # ===================
  # Edge Case Tests
  # ===================

  test "can reject and then sender creates new request" do
    alice = create_user(name: "Alice", email: "alice@example.com")
    bob = create_user(name: "Bob", email: "bob@example.com")

    # First request gets rejected
    first_request = FriendRequest.create!(sender: alice, receiver: bob, status: "pending")
    first_request.reject!

    # Alice tries again - this should fail due to uniqueness
    second_request = FriendRequest.new(sender: alice, receiver: bob, status: "pending")
    assert_not second_request.valid?
  end

  test "receiver can send request back to sender who was rejected" do
    alice = create_user(name: "Alice", email: "alice@example.com")
    bob = create_user(name: "Bob", email: "bob@example.com")

    # Alice sends to Bob, Bob rejects
    first_request = FriendRequest.create!(sender: alice, receiver: bob, status: "pending")
    first_request.reject!

    # Bob can send request to Alice (different direction)
    reverse_request = FriendRequest.new(sender: bob, receiver: alice, status: "pending")
    assert reverse_request.valid?
  end

  test "multiple users can send requests to same receiver" do
    alice = create_user(name: "Alice", email: "alice@example.com")
    bob = create_user(name: "Bob", email: "bob@example.com")
    charlie = create_user(name: "Charlie", email: "charlie@example.com")

    request1 = FriendRequest.create!(sender: alice, receiver: charlie, status: "pending")
    request2 = FriendRequest.create!(sender: bob, receiver: charlie, status: "pending")

    assert request1.persisted?
    assert request2.persisted?
  end

  test "same user can send requests to multiple receivers" do
    alice = create_user(name: "Alice", email: "alice@example.com")
    bob = create_user(name: "Bob", email: "bob@example.com")
    charlie = create_user(name: "Charlie", email: "charlie@example.com")

    request1 = FriendRequest.create!(sender: alice, receiver: bob, status: "pending")
    request2 = FriendRequest.create!(sender: alice, receiver: charlie, status: "pending")

    assert request1.persisted?
    assert request2.persisted?
  end
end
