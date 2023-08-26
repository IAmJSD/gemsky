# frozen_string_literal: true

class SkeetPostImagesEmbedComponent < ViewComponent::Base
    def initialize(did:, images:)
        @did = did
        @images = images
    end
end
