module UsersHelper
  # Generates a Gravatar URL for a given user
  # Gravatar uses MD5 hash of email to generate profile pictures
  # Options:
  #   size: pixel size of the image (default: 80)
  def gravatar_url(user, size: 80)
    # Gravatar requires lowercase, trimmed email hashed with MD5
    gravatar_id = Digest::MD5.hexdigest(user.email.downcase.strip)

    # Use 'identicon' as default image style if user has no Gravatar
    # Other options: 'mp', 'monsterid', 'wavatar', 'retro', 'robohash'
    "https://www.gravatar.com/avatar/#{gravatar_id}?s=#{size}&d=identicon"
  end
end
