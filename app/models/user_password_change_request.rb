class UserPasswordChangeRequest < ApplicationRecord
  include TokenConcern

  return_full_token

  belongs_to :user
  self.token_ttl = 15.minutes

  after_create :send_email

  private

  def send_email
    UserMailer.with(user: self.user, token: self.token).password_change_request.deliver_later
  end
end
