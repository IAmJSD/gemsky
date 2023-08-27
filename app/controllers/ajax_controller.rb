class AjaxController < ApplicationController
    include FeedConcern
    feed_ajax_mode

    before_action :validate_did_permissions!

    def notification_count
        count = @bluesky_user.bluesky_client.get_notification_unread_count
        @bluesky_user.save!
        render json: count
    end
end
