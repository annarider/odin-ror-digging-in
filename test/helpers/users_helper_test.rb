require "test_helper"

class UsersHelperTest < ActionView::TestCase
  test "gravatar_url returns a valid Gravatar URL" do
    # Arrange - use existing fixture
    user = users(:one)

    # Act
    url = gravatar_url(user)

    # Assert - Should generate a displayable Gravatar URL
    assert url.start_with?("https://www.gravatar.com/avatar/")
    assert url.include?("s=80") # default size
    assert url.include?("d=identicon") # default image style
  end

  test "gravatar_url respects size option" do
    # Arrange - use existing fixture
    user = users(:one)

    # Act
    url = gravatar_url(user, size: 150)

    # Assert
    assert url.include?("s=150")
  end

  test "gravatar_url generates different URLs for different users" do
    # Arrange - use existing fixtures
    user1 = users(:one)
    user2 = users(:two)

    # Act
    url1 = gravatar_url(user1)
    url2 = gravatar_url(user2)

    # Assert - Different users should have different profile pictures
    assert_not_equal url1, url2
  end
end
