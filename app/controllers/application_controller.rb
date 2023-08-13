class ApplicationController < ActionController::Base
    def initialize
        # Setup the class.
        super

        # Defines the initial values for the title and description.
        @title = "Clearsky"
        @description = "Clearsky is a client for the Bluesky application."
    end

    attr_accessor :title, :description

    before_action :resolve_token
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

    def resolve_token
        res = UserToken.resolve_token(cookies[:user_token])
        if res.nil?
            # Delete the cookie and return.
            cookies.delete(:user_token)
            return
        end

        # Update the cookie.
        cookies[:user_token] = {
            value: res.token,
            expires: 6.days.from_now, # Probably best to kill the token before it actually dies.
        }

        @user = res.user
    end

    def user_must_authenticate!
        redirect_to_login if @user.nil?
    end
end
