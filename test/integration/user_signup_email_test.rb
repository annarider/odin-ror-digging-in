require "test_helper"

class UserSignupEmailTest < ActionDispatch::IntegrationTest
  # INTEGRATION TESTS - Testing the complete user signup flow
  # Following Sandi Metz principles:
  # - Test BEHAVIOR from the USER'S perspective
  # - Test OUTCOMES (does the email get sent?)
  # - Test state changes (email queue, user creation)
  # - Use REAL objects and actual HTTP requests
  # - Only "stub" is the email delivery itself (external dependency)

  # Rails testing convention: ActiveJob::TestHelper gives us assert_enqueued_email_with
  include ActiveJob::TestHelper

  test "signing up as a new user enqueues a welcome email" do
    # Arrange: Start with clear job queue
    initial_user_count = User.count

    # Act: User signs up through the Devise registration form
    # This tests the ACTUAL behavior a user experiences
    assert_difference "User.count", 1 do
      post user_registration_path, params: {
        user: {
          name: "New Gardener",
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    # Assert: Test OUTCOMES
    # 1. Email was enqueued for the new user
    # The after_create callback should have enqueued exactly one email
    jobs = enqueued_jobs.select { |job| job[:job] == ActionMailer::MailDeliveryJob }
    assert_equal 1, jobs.count, "Expected exactly one email job to be enqueued"

    # 2. User is now signed in (behavior outcome from Devise)
    assert_response :redirect
    follow_redirect!
    assert_response :success

    # 3. Verify the created user exists
    new_user = User.find_by(email: "newuser@example.com")
    assert_not_nil new_user
    assert_equal "New Gardener", new_user.name
  end

  test "welcome email is sent with correct user information after signup" do
    # This test verifies that when a user signs up, an email job is enqueued
    # for that specific user with their correct information

    # Arrange: Clear any existing jobs
    clear_enqueued_jobs

    # Act: Create a new user
    post user_registration_path, params: {
      user: {
        name: "Jane Gardener",
        email: "jane.gardener@example.com",
        password: "securePassword123",
        password_confirmation: "securePassword123"
      }
    }

    # Assert: Verify the user was created with correct data
    user = User.find_by(email: "jane.gardener@example.com")
    assert_not_nil user, "User should be created"
    assert_equal "Jane Gardener", user.name

    # Assert: Verify an email job was enqueued for UserMailer
    jobs = enqueued_jobs.select { |job|
      job[:job] == ActionMailer::MailDeliveryJob &&
      job[:args][0] == "UserMailer" &&
      job[:args][1] == "welcome_email"
    }
    assert_equal 1, jobs.count, "Expected one welcome email job to be enqueued"
  end

  test "multiple user signups each receive their own welcome email" do
    # Arrange: Track initial state
    clear_enqueued_jobs

    # Act: Three users sign up
    # Testing behavior: each user should get their own email
    users_data = [
      { name: "Alice", email: "alice@example.com", password: "password123" },
      { name: "Bob", email: "bob@example.com", password: "password123" },
      { name: "Charlie", email: "charlie@example.com", password: "password123" }
    ]

    users_data.each do |user_data|
      post user_registration_path, params: {
        user: user_data.merge(password_confirmation: user_data[:password])
      }
      # Sign out to allow next registration
      delete destroy_user_session_path
    end

    # Assert: Test OUTCOME - three emails should be enqueued
    assert_equal 3, enqueued_jobs.select { |job|
      job[:job] == ActionMailer::MailDeliveryJob
    }.count

    # Verify each user got created (state change)
    assert User.exists?(email: "alice@example.com")
    assert User.exists?(email: "bob@example.com")
    assert User.exists?(email: "charlie@example.com")
  end

  test "welcome email is NOT sent if user signup fails validation" do
    # Arrange: Clear job queue
    clear_enqueued_jobs
    initial_user_count = User.count

    # Act: Attempt to sign up with invalid data (missing name, per User validation)
    post user_registration_path, params: {
      user: {
        name: "", # Invalid - name is required
        email: "test@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    # Assert: Test OUTCOMES
    # 1. No email should be enqueued (because user wasn't created)
    assert_equal 0, enqueued_jobs.count

    # 2. No user was created (state didn't change)
    assert_equal initial_user_count, User.count

    # 3. User sees the form again with errors (behavior outcome)
    assert_response :unprocessable_entity
    assert_select "div#error_explanation" # Devise shows errors
  end

  test "welcome email contains personalized content for the signed up user" do
    # This test verifies the INTEGRATION between signup and email content
    # We're testing that the correct data flows through the entire system

    # Act: User signs up, and we immediately process background jobs
    # perform_enqueued_jobs wraps the action to process jobs synchronously in tests
    perform_enqueued_jobs do
      post user_registration_path, params: {
        user: {
          name: "Rosa Parks",
          email: "rosa@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    # Assert: Check that the user was created
    user = User.find_by(email: "rosa@example.com")
    assert_not_nil user, "User should be created"

    # Assert: Check the actual email that was sent
    # This tests the complete integration: signup -> callback -> email job -> email delivery
    assert_equal 1, ActionMailer::Base.deliveries.count

    email = ActionMailer::Base.deliveries.last
    assert_equal [ "rosa@example.com" ], email.to
    assert_equal "Welcome to GardenBook!", email.subject
    assert_match "Rosa Parks", email.body.encoded
  end

  test "welcome email uses deliver_later for background processing" do
    # This tests the BEHAVIOR that emails are processed asynchronously
    # Important for performance - we don't want to block user signup

    # Arrange
    clear_enqueued_jobs

    # Act: User signs up
    post user_registration_path, params: {
      user: {
        name: "John Doe",
        email: "john@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    # Assert: Email should be ENQUEUED (not delivered immediately)
    # This is the OUTCOME we want - background processing
    assert_equal 1, enqueued_jobs.count

    # Before processing jobs, deliveries should be empty
    assert_equal 0, ActionMailer::Base.deliveries.count

    # After processing jobs, email is delivered
    perform_enqueued_jobs
    assert_equal 1, ActionMailer::Base.deliveries.count
  end
end
