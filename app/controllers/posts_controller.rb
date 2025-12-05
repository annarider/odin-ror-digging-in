class PostsController < ApplicationController
  before_action :authenticate_user!

  def index
    # Get IDs of the current user and all their friends
    friend_ids = current_user.friends_ids
    user_and_friend_ids = friend_ids + [ current_user.id ]

    # Get posts from current user and all friends, ordered by most recent
    @posts = Post.where(user_id: user_and_friend_ids).order(created_at: :desc)
  end

  def show
    @post = current_user.posts.find(params[:id])
  end

  def new
    @post = current_user.posts.build
  end

  def edit
    @post = current_user.posts.find(params[:id])
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      redirect_to post_path(@post), notice: "New post created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    @post = current_user.posts.find(params[:id])

    if @post.update(post_params)
      redirect_to posts_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post = current_user.posts.find(params[:id])
    @post.destroy
    redirect_to posts_path, notice: "Post deleted"
  end

  private

  def post_params
    params.require(:post).permit(:content, :image)
  end
end
