module EmailConcern
    extend ActiveSupport::Concern

    included do
        before_validation :downcase_email
        validates :email, presence: true, format: {
            with: URI::MailTo::EMAIL_REGEXP,
            message: "must be a valid email address"
        }

        def self.find_by_email(email)
            self.find_by(email: email.downcase.strip)
        end

        private

        def downcase_email
            self.email = self.email.downcase if self.email.present?
        end
    end
end
