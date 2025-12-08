class UsersController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = User.find(params[:id])
    # Load the user's posts ordered by most recent first
    # This follows Rails convention of ordering by created_at descending
    @posts = @user.posts.order(created_at: :desc)
  end
end
