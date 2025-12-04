class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post
  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to @post, notice: "Comment posted."
    else
      render "posts/show", status: :unprocessable_entity
    end
  end

  def update
    @comment = Comment.find(params[:id])

    if @comment.update(comment_params)
      redirect_to @post
    else
      render "posts/show", status: :unprocessable_entity
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy
    redirect_to @post, status: :see_other, notice: "Comment removed."
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def comment_params
    params.require(:comment).permit(:comment)
  end
end
