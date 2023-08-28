# frozen_string_literal: true

class InputComponent < ViewComponent::Base
  def initialize(name:, label:, type: nil, value: nil, description: nil, slim: false)
    @name = name
    @label = label
    @type = type
    @value = value
    @description = description
    @slim = slim
  end

  def type
    @type || 'text'
  end
end
