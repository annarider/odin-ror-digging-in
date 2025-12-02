class FriendRequest < ApplicationRecord
  belongs_to :sender, class_name: "User"
  belongs_to :receiver, class_name: "User"

  validates :sender_id, uniqueness: { scope: :receiver_id, message: "already sent a friend request" }
  validates :status, inclusion: { in: %w[pending accepted rejected] }
  validate :cannot_friend_self
  validate :not_already_friends

  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }
  scope :rejected, -> { where(status: "rejected") }

  def accept!
    update(status: "accepted")
  end

  def reject!
    update(status: "rejected")
  end

  private

  def cannot_friend_self
    if sender_id == receiver_id
      errors.add(:sender_id, "cannot send friend request to yourself")
    end
  end

  def not_already_friends
    return unless sender_id && receiver_id

    if FriendRequest.where(
      "(sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)",
      sender_id, receiver_id, receiver_id, sender_id
    ).where(status: "accepted").exists?
      errors.add(:base, "already friends with this user")
    end
  end
end
