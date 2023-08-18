# frozen_string_literal: true

class ModalComponent < ViewComponent::Base
    def initialize(id:, title:)
        @id = id
        @title = title
    end
end
