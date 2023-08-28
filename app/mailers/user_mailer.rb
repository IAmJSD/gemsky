class UserMailer < ApplicationMailer
    def password_change_request
        @user = params[:user]
        @token = params[:token]
        mail(to: @user.email, subject: 'Gemsky | Password Change Request')
    end

    def new_user_email_confirmation
        @email = params[:email]
        @token = params[:token]
        mail(to: @email, subject: 'Gemsky | New User Email Confirmation')
    end

    def email_update_request
        @user = params[:user]
        @token = params[:token]
        mail(to: @user.email, subject: 'Gemsky | Email Update Request')
    end

    def user_editor_invite
        @email = params[:email]
        @token = params[:token]
        @handle = params[:handle]
        mail(to: @email, subject: "Gemsky | You've been invited to manage #{@handle}")
    end
end
