# frozen_string_literal: true

class SkeetPostEmbedComponent < ViewComponent::Base
    def initialize(embed:, did:)
        @embed = embed
        @did = did
    end
end
