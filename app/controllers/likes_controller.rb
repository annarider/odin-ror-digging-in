class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_likeable, only: :create

  def create
    # Build a new like associated with the current user and the likeable (Post or Comment)
    @like = @likeable.likes.build(user: current_user)

    if @like.save
      redirect_to posts_path, notice: "Successfully liked!"
    else
      redirect_to posts_path, alert: "Couldn't add like."
    end
  end

  def destroy
    # Find the like that belongs to the current user
    @like = current_user.likes.find(params[:id])
    @like.destroy
    redirect_to posts_path, notice: "Like removed."
  end

  private

  # This method handles the polymorphic routing from nested routes
  # It determines whether we're liking a Post or a Comment
  def set_likeable
    if params[:post_id]
      @likeable = Post.find(params[:post_id])
    elsif params[:comment_id]
      @likeable = Comment.find(params[:comment_id])
    end
  end
end
