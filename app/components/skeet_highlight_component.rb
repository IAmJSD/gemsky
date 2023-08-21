# frozen_string_literal: true

class SkeetHighlightComponent < ViewComponent::Base
  def initialize(skeet_body:, user:, bluesky_user:)
    @skeet_body = skeet_body
    @user = user
    @bluesky_user = bluesky_user
  end
end
