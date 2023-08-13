class UserEmailUpdateRequest < ApplicationRecord
  include TokenConcern

  return_full_token
  belongs_to :user
  self.token_ttl = 2.hours

  include EmailConcern

  after_create :send_email

  private

  def send_email
    UserMailer.with(user: self.user, token: self.token).email_update_request.deliver_later
  end
end
