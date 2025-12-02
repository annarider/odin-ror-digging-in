class FriendRequestsController < ApplicationController
  before_action :authenticate_user!

  def index
    @received_requests = current_user.received_requests.pending.includes(:sender)
    @sent_requests = current_user.sent_requests.pending.includes(:sender)
  end

  def create
    @friend_request = current_user.sent_requests.build(receiver_id: params[:receiver_id])

    if @friend_request.save
      redirect_to users_path, notice: "Friend request sent!"
    else
      redirect_to users_path, alert: "Couldn't send friend request."
    end
  end

  def update
    @friend_request = current_user.received_requests.find(params[:id])

    if params[:status] == "accepted"
      @friend_request.accept!
      redirect_to friend_requests_path, notice: "Friend request accepted!"
    elsif params[:status] == "rejected"
      @friend_request.reject!
      redirect_to friend_requests_path, notice: "Friend request rejected."
    end
  end

  def destroy
    @friend_request = current_user.sent_requests.find(params[:id])
    @friend_request.destroy
    redirect_to friend_requests_path, notice: "Friend request canceled."
  end
end
