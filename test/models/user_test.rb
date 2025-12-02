require "test_helper"

class UserTest < ActiveSupport::TestCase
  # Helper to create users quickly
  def create_user(name:, email:)
    User.create!(
      name: name,
      email: email,
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "user can send a friend request" do
    # Arrange
    sender = create_user(name: 'Sender', email: "sender@example.com")
    receiver = create_user(name: 'Receiver', email: "receiver@example.com")

    # Act
    friend_request = FriendRequest.create!(
      sender: sender,
      receiver: receiver,
      status: "pending"
    )

    # Assert
    assert_includes sender.sent_requests, friend_request
    assert_equal receiver, friend_request.receiver
  end

  test "user can receive a friend request" do
    # Arrange
    sender = create_user(name: 'Sender', email: "sender@example.com")
    receiver = create_user(name: 'Receiver', email: "receiver@example.com")

    # Act
    friend_request = FriendRequest.create!(
      sender: sender,
      receiver: receiver,
      status: "pending"
    )

    # Assert
    assert_includes receiver.received_requests, friend_request
    assert_equal sender, friend_request.sender
  end

  test "users become friends when request is accepted" do
    # Arrange
    alice = create_user(name: 'Alice', email: "alice@example.com")
    bob = create_user(name: 'Bob', email: "bob@example.com")
    friend_request = FriendRequest.create!(
      sender: alice,
      receiver: bob,
      status: "pending"
    )

    # Act
    friend_request.accept!

    # Assert
    assert_includes alice.friends_from_sent_requests, bob
    assert_includes bob.friends_from_received_requests, alice
  end

  test "pending_sent_requests returns only pending requests" do
    # Arrange
    alice = create_user(name: 'Alice', email: "alice@example.com")
    bob = create_user(name: 'Bob', email: "bob@example.com")
    charlie = create_user(name: 'Charlie', email: "charlie@example.com")

    FriendRequest.create!(sender: alice, receiver: bob, status: "pending")
    FriendRequest.create!(sender: alice, receiver: charlie, status: "accepted")

    # Act & Assert
    assert_equal 1, alice.pending_sent_requests.count
    assert_includes alice.pending_sent_requests, bob
    assert_not_includes alice.pending_sent_requests, charlie
  end

  test "pending_received_requests returns only pending requests" do
    # Arrange
    alice = create_user(name: 'Alice', email: "alice@example.com")
    bob = create_user(name: 'Bob', email: "bob@example.com")
    charlie = create_user(name: 'Charlie', email: "charlie@example.com")

    FriendRequest.create!(sender: bob, receiver: alice, status: "pending")
    FriendRequest.create!(sender: charlie, receiver: alice, status: "accepted")

    # Act & Assert
    assert_equal 1, alice.pending_received_requests.count
    assert_includes alice.pending_received_requests, bob
    assert_not_includes alice.pending_received_requests, charlie
  end

  test "friend_request_pending? returns true when pending request exists" do
    # Arrange
    alice = create_user(name: 'Alice', email: "alice@example.com")
    bob = create_user(name: 'Bob', email: "bob@example.com")
    FriendRequest.create!(sender: alice, receiver: bob, status: "pending")

    # Act & Assert
    assert alice.friend_request_pending?(bob)
    assert bob.friend_request_pending?(alice)
  end

  test "friend_request_pending? returns false when no pending request" do
    # Arrange
    alice = create_user(name: 'Alice', email: "alice@example.com")
    bob = create_user(name: 'Bob', email: "bob@example.com")

    # Act & Assert
    assert_not alice.friend_request_pending?(bob)
  end

  test "deleting user destroys their sent friend requests" do
    # Arrange
    alice = create_user(name: 'Alice', email: "alice@example.com")
    bob = create_user(name: 'Bob', email: "bob@example.com")
    FriendRequest.create!(sender: alice, receiver: bob, status: "pending")

    # Act
    alice.destroy

    # Assert
    assert_equal 0, FriendRequest.where(sender_id: alice.id).count
  end
end
