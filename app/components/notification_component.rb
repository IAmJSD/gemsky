# frozen_string_literal: true

class NotificationComponent < ViewComponent::Base
  def initialize(type:, body:)
    @type = type
    @body = body
  end

  def pick_color
    case @type
    when 'success'
      'bg-green-600 dark:bg-green-700'
    when 'warning'
      'bg-yellow-600 dark:bg-yellow-700'
    when 'error'
      'bg-red-600 dark:bg-red-700'
    end
  end
end
