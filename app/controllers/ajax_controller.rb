class AjaxController < ApplicationController
    before_action :validate_did_permissions!, only: [:notification_count]

    def notification_count
        count = @bluesky_user.bluesky_client.get_notification_unread_count
        @bluesky_user.save!
        render json: count
    end
end
