class ApplicationController < ActionController::Base
    def initialize
        # Setup the class.
        super

        # Defines the initial values for the title and description.
        @title = "A Website"
        @description = "A website made with the web-scale-rails template."
    end

    attr_accessor :title, :description
end
