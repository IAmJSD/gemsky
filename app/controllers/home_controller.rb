class HomeController < ApplicationController
    before_action :validate_did_permissions!, only: [:home_did]

    def index
        redirect_to '/home'
    end

    def home
        # Get the bluesky users linked to this user.
        @bluesky_users = user.linked_bluesky_users

        # If there are none, redirect to /home/new.
        if @bluesky_users.length == 0
            return redirect_to '/home/new'
        end

        # If it is just one, redirect to /home/:did.
        if @bluesky_users.length == 1
            return redirect_to "/home/#{@bluesky_users[0].did}"
        end

        # Render the user picker.
        render :user_picker
    end

    def new_user; end

    def new_user_post
        BlueskyUser.transaction do
            # Try to create the user.
            permitted = params.permit(:identifier, :token)
            bluesky_user = user.bluesky_users.create(permitted)

            if bluesky_user.errors.any?
                # Check if DID is there but the save didn't succeed, if so,
                # delete the last record with the DID and try again.
                success = false
                unless bluesky_user.did.nil?
                    BlueskyUser.where(did: bluesky_user.did).destroy_all
                    bluesky_user.save!
                    redirect_to "/home/#{bluesky_user.did}"
                    success = true
                end

                # Handle if we weren't successful.
                unless success
                    # Check if either identifier or token is invalid.
                    if bluesky_user.errors[:identifier].length > 0 || bluesky_user.errors[:token].length > 0
                        # Set @errors to the errors (minus did).
                        @errors = bluesky_user.errors.full_messages.reject { |e| e.include?('Did') }
                    end

                    # @errors should be set to a message about being unable to connect.
                    @errors = ['Unable to connect to Bluesky with your identifier and token.'] if @errors.nil?

                    # Render the page.
                    render :new_user, status: :bad_request
                end
            else
                # If there was no errors, redirect to the user's home page.
                redirect_to "/home/#{bluesky_user.did}"
            end
        end
    end

    def home_did
        @highlights = :home
        @timeline = @bluesky_user.bluesky_client.get_timeline
        @bluesky_user.save!
        render :home_did, layout: 'client'
    end
end
