module FeedConcern
    extend ActiveSupport::Concern

    included do
        before_action :validate_did_permissions!, only: [:home_feed]

        def home_feed
            ajax_feed = is_ajax_feed?

            @timeline = @bluesky_user.bluesky_client.get_timeline(
                'reverse-chronological',
                ajax_feed ? 30 : 50,
                get_cursor,
            )
            @bluesky_user.save!
            @ajax_route = '/ajax/home_feed' unless ajax_feed

            render 'turbo_components/feed', layout: !ajax_feed
        end

        private

        def get_cursor
            return nil unless is_ajax_feed?

            # Get the cursor from the request.
            cursor = params[:cursor]

            # Check the cursor is a string.
            raise ActionController::RoutingError.new('Not Found') unless cursor.is_a?(String)

            # Return the cursor.
            cursor
        end

        def is_ajax_feed?
            self.class.instance_variable_defined?(:@feed_ajax_mode)
        end

        def self.feed_ajax_mode
            @feed_ajax_mode = true
        end
    end
end
