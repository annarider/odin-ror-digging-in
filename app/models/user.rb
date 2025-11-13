class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  # Friend requests sent by this user
  has_many :sent_friend_requests, foreign_key: :sender_id, class_name: 'FriendRequest', dependent: :destroy

  # Friend requests received by this user
  has_many :received_friend_requests, foreign_key: :receiver_id, class_name: 'FriendRequest', dependent: :destroy

  # Friends who accepted this user's friend requests
  has_many :friends_from_sent_requests, -> { where(friend_requests: { status: 'accepted' }) },
           through :sent_friend_requests, source: :receiver
  
  # Friends who sent the accepted request to become friends with this user
  has_many :friends_from_received_requests, -> { where(friend_requests: { status: 'accepted' }) },
           through :received_friend_requests, source: :sender
  
  # Pending friend requests this user sent
  has_many :pending_sent_requests, -> { where(status: 'pending') }, 
           class_name: 'FriendRequest', foreign_key: :sender_id

  # Pending friend requests this user received
  has_many :pending_received_requests, -> { where(status: 'pending') },
           class_name: 'FriendRequest', foreign_key: :received_id

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
    sent_friend_requests.pending.exists?(receiver_id: other_user.id) ||
      received_friend_requests.pending.exists?(sender_id: other_user.id)
  end
end
