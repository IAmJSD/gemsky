# frozen_string_literal: true

class SkeetPostRecordEmbedComponent < ViewComponent::Base
    def initialize(did:, embed:)
        @did = did
        @embed = embed
    end
end
