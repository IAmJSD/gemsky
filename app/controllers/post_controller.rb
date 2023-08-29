class PostController < ApplicationController
    include ClientRenderConcern

    skip_before_action :user_must_authenticate!
    before_action :lax_authentication!

    ALLOWED_POST_ID = /^[a-zA-Z0-9._:%-]+$/.freeze

    def view
        begin
            author_did = BlueskyClient.resolve_handle(params[:identifier])
        rescue BlueskyError
            # Raise a 404 if we can't find the author.
            raise ActiveRecord::RecordNotFound
        end

        # Make sure the post ID is a valid format.
        raise ActiveRecord::RecordNotFound unless params[:post_id].match?(ALLOWED_POST_ID)

        # Build the URI.
        uri = "at://#{author_did}/app.bsky.feed.post/#{params[:post_id]}"

        # Get the post.
        begin
            @post = @bluesky_user.bluesky_client.get_post_thread(uri)
        rescue BlueskyError
            # Raise a 404 if we can't find the post.
            raise ActiveRecord::RecordNotFound
        end

        # Write the user.
        @bluesky_user.save!

        # Render view either with the application layout or the client layout.
        render_client(:view) if user
    end

    private

    def lax_authentication!
        # Get the anonymous user if we are not logged in.
        if user.nil?
            # Get the anonymous user from anonymousauth@webscalesoftware.ltd.
            @bluesky_user = BlueskyUser.joins(:user).find_by(users: {
                email: 'anonymousauth@webscalesoftware.ltd',
            })

            # Raise a 404 if we can't find the anonymous user.
            raise ActiveRecord::RecordNotFound if @bluesky_user.nil?

            # Return here since we do not need the rest of the method.
            return
        end

        # Get all the linked bluesky users.
        @bluesky_users = user.linked_bluesky_users

        # Redirect to /home/new if we have no linked bluesky users.
        redirect_to '/home/new', status: :see_other if @bluesky_users.empty?

        # Get the authed_did from the params.
        authed_did = params[:authed_did]

        # If it is nil, just get the first linked bluesky user.
        if authed_did.nil?
            @bluesky_user = @bluesky_users.first
            return
        end

        # Get the bluesky user from the authed_did.
        @bluesky_user = @bluesky_users.find { |u| u.did == authed_did }

        # If we can't find the bluesky user, go back to the first linked bluesky user.
        @bluesky_user = @bluesky_users.first if @bluesky_user.nil?
    end
end
