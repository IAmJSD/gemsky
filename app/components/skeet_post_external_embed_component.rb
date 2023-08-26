# frozen_string_literal: true

class SkeetPostExternalEmbedComponent < ViewComponent::Base
    def initialize(did:, external:)
        @did = did
        @external = external
    end
end
