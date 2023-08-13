class NewUserEmailConfirmation < ApplicationRecord
    include EmailConcern

    validate :email_not_used_by_other_user
    attr_accessor :user_owning_email_limiting_factor

    include TokenConcern

    return_full_token
    self.token_wraps = :email
    self.token_ttl = 2.hours

    after_create :send_email

    private

    def email_not_used_by_other_user
        if User.find_by(email: self.email)
            errors.add(:email, "is already used by another user")
            self.user_owning_email_limiting_factor = true
        end
    end

    def send_email
        UserMailer.with(email: self.email, token: self.token).new_user_email_confirmation.deliver_later
    end
end
