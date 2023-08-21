# frozen_string_literal: true

class SkeetCompactComponent < ViewComponent::Base
    def initialize(skeet_body:, user:, bluesky_user:)
        @skeet_body = skeet_body
        @user = user
        @bluesky_user = bluesky_user
    end


    def time_ago_shorthand(time)
        time_ago_in_words(time, scope: 'datetime.distance_in_words.abbrv')
   end
end
    