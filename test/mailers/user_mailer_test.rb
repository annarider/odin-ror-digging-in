require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "welcome_email sends to correct user with correct subject" do
    # Create a test user
    user = User.new(
      name: "Test Gardener",
      email: "test@example.com",
      password: "password123"
    )

    # Generate the welcome email
    mail = UserMailer.welcome_email(user)

    # Test the email headers
    assert_equal "Welcome to GardenBook!", mail.subject
    assert_equal [ "test@example.com" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
  end

  test "welcome_email includes user name and relevant content" do
    user = User.new(
      name: "Jane Doe",
      email: "jane@example.com",
      password: "password123"
    )

    mail = UserMailer.welcome_email(user)

    # Test the email body contains personalized content
    assert_match "Welcome to GardenBook, Jane Doe!", mail.body.encoded
    assert_match "gardening enthusiasts", mail.body.encoded
    assert_match "Visit GardenBook", mail.body.encoded
  end
end
