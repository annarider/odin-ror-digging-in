class CommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_comment, only: [ :update, :destroy ]

  def create
    @commentable = find_commentable # polymorphic - could be post, comment, etc.
    @comment = @commentable.comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      redirect_to root_post, notice: "Comment posted."
    else
      # Set @post for the view - find the root post from @commentable
      @post = find_root_post(@commentable)
      render "posts/show", status: :unprocessable_entity
    end
  end

  def update
    if @comment.update(comment_params)
      redirect_to root_post
    else
      render "posts/show", status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy
    redirect_to root_post, status: :see_other, notice: "Comment removed."
  end

  private

  def set_comment
    @comment = current_user.comments.find(params[:id])
  end

  def find_commentable
    # Check params to find what user is commenting on
    if params[:post_id]
      Post.find(params[:post_id])
    elsif params[:comment_id]
      Comment.find(params[:comment_id])
    end
  end

  # Helper method to find the root post for any comment
  # Traverses up the polymorphic chain to find the original Post
  def root_post
    commentable = @comment.commentable
    # Keep going up the chain until we hit a Post
    while commentable.is_a?(Comment)
      commentable = commentable.commentable
    end
    commentable # This will be the Post
  end

  # Find the root post from any commentable object
  def find_root_post(commentable)
    while commentable.is_a?(Comment)
      commentable = commentable.commentable
    end
    commentable # This will be the Post
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end
