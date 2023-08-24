class AjaxController < ApplicationController
    before_action :validate_did_permissions!

    def notification_count
        count = @bluesky_user.bluesky_client.get_notification_unread_count
        @bluesky_user.save!
        render json: count
    end

    def home_feed
        # Check the cursor is a string.
        raise ActionController::RoutingError.new('Not Found') unless params[:cursor].is_a?(String)

        # Get the timeline.
        @timeline = @bluesky_user.bluesky_client.get_timeline(
            'reverse-chronological',
            30,
            params[:cursor],
        )

        # Render the feed turbo component.
        render 'turbo_components/feed', layout: false
    end
end
