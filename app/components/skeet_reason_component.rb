# frozen_string_literal: true

class SkeetReasonComponent < ViewComponent::Base
  def initialize(reason:)
    @reason = reason
  end
end
