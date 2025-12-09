class UserMailer < ApplicationMailer
  # Sends a welcome email to a newly registered user
  # @param user [User] the user who just signed up
  def welcome_email(user)
    @user = user
    @url = root_url

    mail(
      to: @user.email,
      subject: "Welcome to GardenBook!"
    )
  end
end
