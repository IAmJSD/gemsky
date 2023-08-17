class User < ApplicationRecord
    include EmailConcern
    validates :email, uniqueness: true

    has_secure_password

    has_many :user_tokens, dependent: :destroy
    has_many :half_tokens, dependent: :destroy
    has_many :user_password_change_requests, dependent: :destroy
    has_many :totp_recovery_codes, dependent: :destroy
    has_one :user_email_update_request, dependent: :destroy
    has_many :bluesky_users, dependent: :destroy
    has_many :bluesky_user_editors, dependent: :destroy

    def logout!
        self.user_tokens.destroy_all
        self.half_tokens.destroy_all
    end

    def linked_bluesky_users
        BlueskyUser.joins(:bluesky_user_editors).where(bluesky_user_editors: { user_id: self.id })
    end
end
