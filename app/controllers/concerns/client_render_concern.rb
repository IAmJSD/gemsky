module ClientRenderConcern
    extend ActiveSupport::Concern

    included do
        private

        def render_client(component, props = {})
            begin
                @profile = @bluesky_user.bluesky_client.get_profile
            rescue BlueskyError => e
                # Handle if it is a ExpiredToken error.
                return render 'application/reauth', status: :unauthorized if e.error == 'ExpiredToken'
                raise e
            end

            render component, layout: 'client', locals: props
        end
    end
end
