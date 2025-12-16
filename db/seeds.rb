# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Clearing existing data..."
Like.destroy_all
Comment.destroy_all
FriendRequest.destroy_all
Post.destroy_all
User.destroy_all

puts "Creating users..."

# Create users with gardening-themed names
users = [
  { name: "Rose Gardner", email: "rose@example.com", password: "password123" },
  { name: "Lily Chen", email: "lily@example.com", password: "password123" },
  { name: "Basil Thompson", email: "basil@example.com", password: "password123" },
  { name: "Ivy Martinez", email: "ivy@example.com", password: "password123" },
  { name: "Sage Williams", email: "sage@example.com", password: "password123" },
  { name: "Jasmine Patel", email: "jasmine@example.com", password: "password123" },
  { name: "Oliver Green", email: "oliver@example.com", password: "password123" },
  { name: "Flora Anderson", email: "flora@example.com", password: "password123" }
]

created_users = users.map do |user_data|
  User.create!(user_data)
end

puts "Created #{created_users.length} users"

puts "Creating friend relationships..."

# Create some accepted friendships
friend_pairs = [
  [created_users[0], created_users[1]], # Rose & Lily
  [created_users[0], created_users[2]], # Rose & Basil
  [created_users[1], created_users[2]], # Lily & Basil
  [created_users[1], created_users[3]], # Lily & Ivy
  [created_users[3], created_users[4]], # Ivy & Sage
  [created_users[4], created_users[5]], # Sage & Jasmine
  [created_users[2], created_users[6]], # Basil & Oliver
  [created_users[6], created_users[7]]  # Oliver & Flora
]

friend_pairs.each do |user1, user2|
  FriendRequest.create!(sender: user1, receiver: user2, status: "accepted")
end

# Create some pending friend requests
FriendRequest.create!(sender: created_users[0], receiver: created_users[4], status: "pending")
FriendRequest.create!(sender: created_users[7], receiver: created_users[1], status: "pending")

puts "Created #{FriendRequest.count} friend requests"

puts "Creating posts..."

posts_data = [
  { user: created_users[0], content: "Just harvested my first tomatoes of the season! The heirloom varieties are absolutely stunning. 🍅" },
  { user: created_users[1], content: "My herb garden is thriving! Fresh basil, mint, and rosemary for tonight's dinner." },
  { user: created_users[2], content: "Does anyone have tips for dealing with aphids on roses? Trying to avoid harsh chemicals." },
  { user: created_users[3], content: "Started my first compost bin today. Excited to create my own nutrient-rich soil!" },
  { user: created_users[4], content: "The lavender is finally blooming! The bees are absolutely loving it." },
  { user: created_users[0], content: "Planting day! Got some new seedlings: cucumbers, zucchini, and bell peppers. Can't wait to see them grow!" },
  { user: created_users[5], content: "My sunflowers are taller than me now! They're over 6 feet tall. Nature is amazing." },
  { user: created_users[6], content: "First time growing carrots and they turned out great! The kids loved pulling them from the ground." },
  { user: created_users[7], content: "My butterfly garden is attracting so many monarchs this year! Worth every minute of planning." },
  { user: created_users[1], content: "Just finished building raised beds. Ready for spring planting!" }
]

created_posts = posts_data.map do |post_data|
  Post.create!(post_data)
end

puts "Created #{created_posts.length} posts"

puts "Creating comments..."

comments_data = [
  { user: created_users[1], commentable: created_posts[0], content: "Those look delicious! What varieties did you plant?" },
  { user: created_users[2], commentable: created_posts[0], content: "Beautiful! I love growing heirlooms too." },
  { user: created_users[0], commentable: created_posts[2], content: "Try neem oil spray! It works great and is organic." },
  { user: created_users[3], commentable: created_posts[2], content: "Ladybugs are natural predators of aphids. You can buy them online!" },
  { user: created_users[4], commentable: created_posts[3], content: "Composting is so rewarding! Make sure to turn it regularly." },
  { user: created_users[2], commentable: created_posts[4], content: "Lavender is one of my favorites. The smell is incredible!" },
  { user: created_users[6], commentable: created_posts[5], content: "Good luck with your planting! Keep us updated on the progress." },
  { user: created_users[0], commentable: created_posts[9], content: "Raised beds are the best! So much easier on the back." }
]

comments_data.each do |comment_data|
  Comment.create!(comment_data)
end

puts "Created #{Comment.count} comments"

puts "Creating likes..."

# Add likes to various posts and comments
like_combinations = [
  [created_users[1], created_posts[0]],
  [created_users[2], created_posts[0]],
  [created_users[3], created_posts[0]],
  [created_users[0], created_posts[1]],
  [created_users[2], created_posts[1]],
  [created_users[0], created_posts[2]],
  [created_users[1], created_posts[2]],
  [created_users[4], created_posts[3]],
  [created_users[2], created_posts[4]],
  [created_users[3], created_posts[4]],
  [created_users[6], created_posts[6]],
  [created_users[0], Comment.first],
  [created_users[2], Comment.second]
]

like_combinations.each do |user, likeable|
  Like.create!(user: user, likeable: likeable)
end

puts "Created #{Like.count} likes"

puts "\n" + "="*50
puts "Seeding completed successfully!"
puts "="*50
puts "\nYou can log in with any of these accounts:"
puts "Email: rose@example.com    | Password: password123"
puts "Email: lily@example.com    | Password: password123"
puts "Email: basil@example.com   | Password: password123"
puts "Email: ivy@example.com     | Password: password123"
puts "Email: sage@example.com    | Password: password123"
puts "Email: jasmine@example.com | Password: password123"
puts "Email: oliver@example.com  | Password: password123"
puts "Email: flora@example.com   | Password: password123"
puts "="*50
