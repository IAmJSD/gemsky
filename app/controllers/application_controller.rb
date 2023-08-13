class ApplicationController < ActionController::Base
    def initialize
        # Setup the class.
        super

        # Defines the initial values for the title and description.
        @title = "Clearsky"
        @description = "Clearsky is a client for the Bluesky application."
    end

    attr_accessor :title, :description

    before_action :user_must_authenticate!
    attr_accessor :user
    helper_method :user

    private

    def redirect_to_login
        # Get the path.
        path = request.path

        # Generate the params.
        params = {
            redirect_to: path,
        }.to_query

        # Redirect to the login page.
        redirect_to "/login?#{params}"
    end

    def user_must_authenticate!
        res = UserToken.resolve_token(cookies[:user_token])
        return redirect_to_login if res.nil?

        @user = res.user        
    end
end
