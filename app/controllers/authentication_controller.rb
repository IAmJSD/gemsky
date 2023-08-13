class AuthenticationController < ApplicationController
    skip_before_action :user_must_authenticate!
    before_action :user_must_not_authenticate!, except: [:email_change_token_click, :logout]

    CONSTANT_TIME_BCRYPT_HASH = BCrypt::Password.create('1234567890')

    def login; end

    def totp_handler
        # Get the half token.
        half_token = HalfToken.resolve_token(params[:half_token])
        if half_token.nil?
            # It probably expired. Re-render the login page.
            return render 'login'
        end

        # Get the user.
        user = half_token.user

        # Get the TOTP code.
        if user.totp_secret.present?
            res = validate_totp(user)
            if !res
                @error = 'Invalid TOTP code.'
                return render 'login_totp', status: :unauthorized
            end
        end

        # Upgrade the token.
        user_token = half_token.upgrade!
        cookies[:user_token] = {
            value: user_token.token,
            expires: 6.days.from_now, # Probably best to kill the token before it actually dies.
        }

        # End the auth flow.
        end_of_auth_flow
    end

    def login_post
        # If this has the parameter type of totp, then render the totp page.
        if params[:type] == 'totp'
            return totp_handler
        end

        # Get the email and password.
        email = params[:email]
        password = params[:password]

        # Find the user.
        user = User.find_by_email(email)
        if user.nil?
            @error = 'Invalid email or password.'

            # Compare the password to the constant time hash. This is to prevent
            # timing attacks.
            BCrypt::Password.new(CONSTANT_TIME_BCRYPT_HASH) == password

            return render 'login', status: :unauthorized
        end

        # Check the password.
        if !user.authenticate(password)
            @error = 'Invalid email or password.'
            return render 'login', status: :unauthorized
        end

        # If the user has a TOTP secret, then render the TOTP page and make a half token.
        if user.totp_secret.present?
            params[:half_token] = HalfToken.create!(user: user).token
            return render 'login_totp'
        end

        # Create a user token.
        user_token = UserToken.create!(user: user)
        cookies[:user_token] = {
            value: user_token.token,
            expires: 6.days.from_now, # Probably best to kill the token before it actually dies.
        }

        # End the auth flow.
        end_of_auth_flow
    end

    def logout
        # Delete the cookie.
        cookies.delete(:user_token)

        # Call the logout method on the user.
        user.logout! unless user.nil?

        # Redirect to the root.
        redirect_to '/', status: :see_other
    end

    def forgot_password_enter_email; end

    def forgot_password_enter_email_post
        # Find the user by email.
        user = User.find_by_email(params[:email])
        if user.nil?
            # The user doesn't exist but we can't tell the user that.
            @maybe_successful = true
            return render 'forgot_password_enter_email'
        end

        # Create a password change request.
        UserPasswordChangeRequest.create!(user: user)
        @maybe_successful = true
        render 'forgot_password_enter_email'
    end

    def forgot_password_remainder
        x = UserPasswordChangeRequest.resolve_token!(params[:token])
        @has_totp = x.user.totp_secret.present?
    end

    def forgot_password_remainder_post
        # Get the password change request.
        token = UserPasswordChangeRequest.resolve_token!(params[:token])
        @has_totp = token.user.totp_secret.present?

        # Check if TOTP is valid if relevant.
        if @has_totp
            res = validate_totp(token.user)
            if !res
                @error = 'Invalid TOTP code.'
                return render 'forgot_password_remainder', status: :unauthorized
            end
        end

        # Update the password.
        token.user.update(password: params[:password], password_confirmation: params[:password_confirmation])
        if token.user.errors.any?
            @error = token.user.errors.full_messages.first
            return render 'forgot_password_remainder', status: :bad_request
        end

        # Delete the token.
        token.destroy!

        # Redirect to the login page.
        redirect_to '/login'
    end

    def register_enter_email; end

    def register_enter_email_post
        # Try and create a new user email confirmation.
        res = NewUserEmailConfirmation.create(email: params[:email])
        if res.errors.any?
            # Check if the error is not that the email is already used by another user.
            unless res.user_owning_email_limiting_factor
                @error = res.errors.full_messages.first
                return render 'register_enter_email', status: :bad_request
            end
        end

        # Render the register enter email page.
        @maybe_successful = true
        render 'register_enter_email'
    end

    def register_remainder
        # Make sure the token is valid.
        NewUserEmailConfirmation.resolve_token!(params[:token])
    end

    def register_remainder_post
        # Get the token.
        token = NewUserEmailConfirmation.resolve_token!(params[:token])

        # Create the user.
        user = User.create(email: token.email, password: params[:password], password_confirmation: params[:password_confirmation])
        if user.errors.any?
            @error = user.errors.full_messages.join('\n')
            return render 'register_remainder', status: :bad_request
        end

        # Destroy the token.
        token.destroy!

        # Create a user token.
        user_token = UserToken.create!(user: user)
        cookies[:user_token] = {
            value: user_token.token,
            expires: 6.days.from_now, # Probably best to kill the token before it actually dies.
        }

        # End the auth flow.
        end_of_auth_flow
    end

    def email_change_token_click
        token = EmailChangeRequest.resolve_token!(params[:token])
        token.user.update(email: token.email)
        if token.user.errors.any?
            # Render the first error.
            @error = token.user.errors.full_messages.first
            return render 'email_change_token_click_error', status: :bad_request
        end
        token.destroy!
        render 'email_change_token_click'
    end

    private

    def end_of_auth_flow
        # Make sure redirect_to is a path and not a url.
        redirect_to = params[:redirect_to]
        redirect_to = nil if redirect_to.blank?
        redirect_to = URI.parse(redirect_to).path if redirect_to.present?

        # Redirect to the path.
        redirect_to redirect_to || "/home"
    end

    def user_must_not_authenticate!
        end_of_auth_flow if @user.present?
    end

    def format_totp_code(code)
        return code unless code.is_a?(String)

        # Remove all non-digit characters.
        code = code.gsub(/\D/, '')

        # Return the code.
        code
    end

    def validate_totp(user)
        totp_code = format_totp_code(params[:totp_code])
        totp = ROTP::TOTP.new(user.totp_secret, issuer: 'Clearsky', drift_behind: 30)
        if !totp.verify(totp_code)
            # Downcase and strip the code.
            totp_code = params[:totp_code].downcase.strip

            # Check if the code is a recovery code.
            recovery_code = TotpRecoveryCode.find_by(user: user, code: totp_code)
            if recovery_code.nil?
                # It's not a recovery code. Re-render the login page.
                return false
            end

            # Delete the recovery code.
            recovery_code.destroy!
        end
        return true
    end
end
