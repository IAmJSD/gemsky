class ApplicationController < ActionController::Base
    attr_accessor :title, :description

    def initialize
        # Setup the class.
        super

        # Defines the initial values for the title and description.
        @title = "Clearsky"
        @description = "Clearsky is a client for the Bluesky application."
    end
end
