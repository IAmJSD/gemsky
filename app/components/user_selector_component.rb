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
  end

  private

  def gracefully_handle_user(user)
    # Get the user's profile.
    user.bluesky_client.get_profile
  rescue
    begin
      # Try to get the user's profile with some other client.
      another_user = @users.find { |u| u != user }
      another_user.bluesky_client.get_profile(user.did)
    rescue => e
      # Return just the did.
      { 'did' => user.did }
    end
  end
end
