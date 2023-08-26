# frozen_string_literal: true

class SkeetPostEmbedComponent < ViewComponent::Base
    def initialize(embed:, outer_embed:, did:)
        @embed = embed
        @outer_embed = outer_embed
        @did = did
    end
end
