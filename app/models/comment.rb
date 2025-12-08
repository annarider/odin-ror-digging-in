class Comment < ApplicationRecord
  belongs_to :user
  # Defines child polymorphic association name
  belongs_to :commentable, polymorphic: true

  # Allows comments to have child comments
  has_many :comments, as: :commentable

  # Allows comments to be liked
  has_many :likes, as: :likeable, dependent: :destroy

  validates :content, presence: true
end
