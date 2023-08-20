# frozen_string_literal: true

class SkeetHighlightComponent < ViewComponent::Base
  def initialize(skeet_body:)
    @skeet_body = skeet_body
  end
end
