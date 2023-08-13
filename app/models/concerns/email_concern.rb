module EmailConcern
    extend ActiveSupport::Concern

    included do
        before_validation :downcase_email
        validates :email, presence: true, format: {
            with: URI::MailTo::EMAIL_REGEXP,
            message: "must be a valid email address"
        }

        private

        def downcase_email
            self.email = self.email.downcase if self.email.present?
        end
    end
end
