class TurboComponentsController < ApplicationController
    include FeedConcern

    before_action :must_be_turbo_request!

    def user_list; end

    private

    def must_be_turbo_request!
        # If the request is not a turbo request, return a 404.
        raise ActionController::RoutingError.new('Not Found') unless request.headers['Turbo-Frame'].present?
    end
end
