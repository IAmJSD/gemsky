# frozen_string_literal: true

class SkeetPostEmbedComponent < ViewComponent::Base
    def initialize(embed:)
        @embed = embed
    end
end
