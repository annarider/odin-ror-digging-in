class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Friend requests this user sent - get FriendRequest Objects
  has_many :sent_requests, foreign_key: :sender_id, class_name: 'FriendRequest', dependent: :destroy

  # Friend requests this user received - get FriendRequest Objects
  has_many :received_requests, foreign_key: :receiver_id, class_name: 'FriendRequest', dependent: :destroy

  # Friends who accepted this user's friend request
  has_many :friends_from_sent_requests, -> { accepted }, through: :sent_requests, source: :receiver

  # Friends who sent this user's a friend request
  has_many :friends_from_received_requests, -> { accepted }, through: :received_requests, source: :sender

  # Get all friends (both directions)
  def friends
    User.where(id: friends_id)
  end

  # Get all friends' IDs
  def friends_ids
    friends_from_sent_requests.pluck(:id) + friends_from_received_requests.pluck(:id)
  end

  # Is this user a friend?
  def friend?(other_user)
    friend_ids.include?(other_user.id)
  end

  def friend_request_pending?(other_user)
    sent_requests.pending.exists?(receiver_id: other_user.id) ||
      received_requests.pending.exists?(sender_id: other_user.id)
  end
end
