class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [ :show, :edit, :update ]
  before_action :authorize_user!, only: [ :edit, :update ]

  def index
    # Load all users except the current user
    # We exclude current_user since you can't send a friend request to yourself
    @users = User.where.not(id: current_user.id).order(:name)
  end

  def show
    # Load the user's posts ordered by most recent first
    # This follows Rails convention of ordering by created_at descending
    @posts = @user.posts.order(created_at: :desc)
  end

  def edit
    # Edit form for user profile
    # The @user instance variable is set by the before_action
  end

  def update
    # Update user profile with new attributes
    if @user.update(user_params)
      # redirect_to is Rails convention for successful updates
      redirect_to user_path(@user), notice: "Profile updated successfully!"
    else
      # render :edit keeps the user on the form and shows validation errors
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    # DRY principle: extract repeated User.find into a before_action
    @user = User.find(params[:id])
  end

  def authorize_user!
    # Security: Users can only edit their own profile
    unless @user == current_user
      redirect_to root_path, alert: "You can only edit your own profile."
    end
  end

  def user_params
    # Strong parameters: whitelist only the attributes we allow users to update
    # This is a security best practice in Rails to prevent mass assignment vulnerabilities
    params.require(:user).permit(:name, :avatar)
  end
end
