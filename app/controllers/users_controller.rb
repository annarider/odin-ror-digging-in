class UsersController < ApplicationController
  before_action :authenticate_user!

  def index
    # Load all users except the current user
    # We exclude current_user since you can't send a friend request to yourself
    @users = User.where.not(id: current_user.id).order(:name)
  end

  def show
    @user = User.find(params[:id])
    # Load the user's posts ordered by most recent first
    # This follows Rails convention of ordering by created_at descending
    @posts = @user.posts.order(created_at: :desc)
  end
end
