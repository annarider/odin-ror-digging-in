class Comment < ApplicationRecord
  belongs_to :user
  # Defines child polymorphic association name
  belongs_to :commentable, polymorphic: true

  # Allows comments to have child comments
  has_many :comments, as: :commentable
end
