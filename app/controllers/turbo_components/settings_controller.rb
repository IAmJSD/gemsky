module TurboComponents
    class SettingsController < TurboComponentsController
        before_action :validate_did_permissions!, except: [:user_settings, :user_settings_patch]
        before_action :must_own_bluesky_user!, only: [:bluesky_user_settings_delete, :bluesky_user_settings_delete_member]
        skip_before_action :must_be_turbo_request!
        before_action :must_be_turbo_request!, only: [:user_settings, :bluesky_user_settings]
        helper_method :owns_bluesky_user?

        def user_settings; end

        EMAIL_INVITE_SUCCESS = 'If the user has a Gemsky account, a e-mail will be sent to them.'.freeze
        OWNER_ERROR = 'You must be the owner of this Bluesky User to perform this action.'.freeze

        def user_settings_patch
            # TODO
            render 'user_settings'
        end

        def bluesky_user_settings; end

        def bluesky_user_settings_patch
            # Handle if the Bluesky user gets a email to handle.
            if params[:email].present?
                # Raise a error if the user does not own the Bluesky user.
                @errors = [OWNER_ERROR] unless owns_bluesky_user?
                return render 'bluesky_user_settings' if @errors.present?

                # Get the user with the email.
                s = params[:email].is_a?(String) ? params[:email] : ''
                user = User.find_by(email: s.downcase.strip)
                if user.nil?
                    # We do not want to tip off the user at
                    # the presence of a Gemsky account or not.
                    @success = EMAIL_INVITE_SUCCESS
                    return render 'bluesky_user_settings'
                end

                # Try to create the invite.
                res = UserEditorInvite.create(bluesky_user: @bluesky_user, user: user)
                if res.errors.any?
                    @errors = res.errors.full_messages
                    return render 'bluesky_user_settings', status: :bad_request
                end

                # Send the success message.
                @success = EMAIL_INVITE_SUCCESS
                return render 'bluesky_user_settings'
            end

            # Handle if a owner tries to transfer ownership.
            if params[:new_owner_email].present?
                # Raise a error if the user does not own the Bluesky user.
                @errors = [OWNER_ERROR] unless owns_bluesky_user?
                return render 'bluesky_user_settings' if @errors.present?

                # Find the user in the editors.
                s = params[:new_owner_email].is_a?(String) ? params[:new_owner_email] : ''
                editor = @bluesky_user.bluesky_user_editors.joins(:user).
                    find_by(users: { email: s.downcase.strip })

                # Raise a error if the user is not a editor.
                @errors = ['The user must be a editor to transfer ownership.'] if editor.nil?
                return render 'bluesky_user_settings' if @errors.present?

                # Raise a error if the user is already a owner.
                editor = editor.user
                @errors = ['The user is already a owner.'] if editor == @bluesky_user.user
                return render 'bluesky_user_settings' if @errors.present?

                # Transfer ownership.
                @bluesky_user.user = editor
                @bluesky_user.save!

                # Send the success message.
                @success = 'Ownership transferred.'
                return render 'bluesky_user_settings'
            end

            # TODO
            render 'bluesky_user_settings'
        end

        def bluesky_user_settings_delete
            # https://www.youtube.com/watch?v=Soa3gO7tL-c
            @bluesky_user.destroy!
            redirect_to '/home', status: :see_other
        end

        def bluesky_user_settings_delete_member
            # Just render the page if the email is not a string.
            email = params[:email]
            return render 'bluesky_user_settings' unless email.is_a?(String)

            # Find the editor.
            editor = @bluesky_user.bluesky_user_editor.joins(:user).
                find_by(users: { email: email.downcase.strip })

            # If we didn't find the editor, just return the settings.
            return render 'bluesky_user_settings' if editor.nil?

            # Try to destroy the editor.
            editor.destroy

            # Render the settings.
            @errors = editor.errors.full_messages unless editor.errors.empty?
            render 'bluesky_user_settings'
        end

        private

        def owns_bluesky_user?
            @bluesky_user.user == user
        end

        def must_own_bluesky_user!
            # The idea here is that for many situations, it is okay if a editor makes a change, but for more destructive changes,
            # it should be the owner. Getting to this stage means either there was a little race or the person is doing bad things.
            render html: 'You must be the owner of this Bluesky User to perform this action.', status: :forbidden unless owns_bluesky_user?
        end
    end
end
