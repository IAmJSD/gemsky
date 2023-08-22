# frozen_string_literal: true

class UserSelectorComponent < ViewComponent::Base
  def initialize(users:)
    @users = users
  end

  def resolved_users
    return @resolved_users unless @resolved_users.nil?
    threads = @users.map do |user|
      Thread.new {
        gracefully_handle_user(user)
      }
    end
    @resolved_users = threads.map(&:value)
    @users.each do |user|
      user.save!
    end
    @resolved_users
  end

  private

  def gracefully_handle_user(user)
    # Get the user's profile.
    user.bluesky_client.get_profile
  rescue BlueskyError => e
    Rails.logger.error("Failed to get DID: #{e.error}: #{e.message} - ttempting with another token if possible!")
    begin
      # Try to get the user's profile with some other client.
      another_user = @users.find { |u| u != user }
      another_user.bluesky_client.get_profile(user.did)
    rescue BlueskyError => e
      # Return just the did.
      Rails.logger.error("Failed to get DID: #{e.error}: #{e.message} - giving up!")
      { 'did' => user.did }
    end
  end
end
