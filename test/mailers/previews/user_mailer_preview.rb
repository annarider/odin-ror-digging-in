# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/welcome_email
  def welcome_email
    # Create a sample user for preview purposes (not saved to database)
    user = User.new(
      name: "Jane Gardener",
      email: "jane@example.com"
    )
    UserMailer.welcome_email(user)
  end
end
