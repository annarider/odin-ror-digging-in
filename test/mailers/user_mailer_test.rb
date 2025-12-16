require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  # UNIT TESTS - Testing UserMailer behavior
  # Following Sandi Metz principles:
  # - Test OUTCOMES (what the email contains), not implementation
  # - Test from USER'S perspective (what would the recipient see?)
  # - Use REAL objects (User) instead of mocks/stubs
  # - Focus on STATE (the email object) and RETURN VALUES

  test "welcome_email creates an email with correct recipients and subject" do
    # Arrange: Create a real user object (not a stub - User is not expensive)
    user = User.new(
      name: "Test Gardener",
      email: "test@example.com",
      password: "password123"
    )

    # Act: Generate the email
    mail = UserMailer.welcome_email(user)

    # Assert: Test the OUTCOME - what the email object contains
    assert_equal "Welcome to GardenBook!", mail.subject
    assert_equal [ "test@example.com" ], mail.to
    assert_equal [ "from@example.com" ], mail.from
  end

  test "welcome_email personalizes greeting with user's name" do
    # Arrange: User with a specific name
    user = User.new(
      name: "Jane Doe",
      email: "jane@example.com",
      password: "password123"
    )

    # Act: Generate the email
    mail = UserMailer.welcome_email(user)

    # Assert: Test OUTCOME - the email body contains personalized greeting
    # This is what the USER will see, so it's the important behavior to test
    assert_match "Welcome to GardenBook, Jane Doe!", mail.body.encoded
  end

  test "welcome_email contains key information about the platform" do
    # Arrange
    user = User.new(
      name: "Bob Smith",
      email: "bob@example.com",
      password: "password123"
    )

    # Act
    mail = UserMailer.welcome_email(user)

    # Assert: Test OUTCOME - email explains what GardenBook is for
    # From user's perspective: "What is this site I signed up for?"
    assert_match "gardening enthusiasts", mail.body.encoded
    assert_match "Share your gardening journey", mail.body.encoded
    assert_match "Connect with fellow gardeners", mail.body.encoded
  end

  test "welcome_email includes a link to visit the site" do
    # Arrange
    user = User.new(
      name: "Alice Green",
      email: "alice@example.com",
      password: "password123"
    )

    # Act
    mail = UserMailer.welcome_email(user)

    # Assert: Test OUTCOME - user can click to visit the site
    # From user's perspective: "How do I get back to the site?"
    assert_match "Visit GardenBook", mail.body.encoded
    # Rails test environment uses http://example.com/ as the default root URL
    assert_match "http://example.com/", mail.body.encoded
  end

  test "welcome_email renders as HTML" do
    # Arrange
    user = User.new(
      name: "Charlie Brown",
      email: "charlie@example.com",
      password: "password123"
    )

    # Act
    mail = UserMailer.welcome_email(user)

    # Assert: Test OUTCOME - email is properly formatted
    # Rails generates multipart emails (both HTML and plain text versions)
    assert_equal "multipart/alternative", mail.content_type.split(";").first
    assert_match "<html>", mail.body.encoded
    # Check that HTML part exists
    assert mail.html_part.present?
    assert_equal "text/html", mail.html_part.content_type.split(";").first
  end

  test "welcome_email works with different user names" do
    # Arrange: Test with a name that has special characters
    user = User.new(
      name: "María José O'Connor",
      email: "maria@example.com",
      password: "password123"
    )

    # Act
    mail = UserMailer.welcome_email(user)

    # Assert: Test OUTCOME - names with special chars are handled correctly
    # Email bodies use quoted-printable encoding, so we need to decode first
    # The HTML part will have the user's name properly rendered
    html_body = mail.html_part.body.decoded
    # Note: ERB HTML-escapes apostrophes as &#39; for safety
    assert_match "María José", html_body
    assert_match "O&#39;Connor", html_body # HTML-escaped apostrophe
    assert_equal [ "maria@example.com" ], mail.to
  end
end
