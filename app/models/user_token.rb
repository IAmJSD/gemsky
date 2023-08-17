class UserToken < ApplicationRecord
  include TokenConcern

  return_full_token

  belongs_to :user
  self.token_ttl = 7.days
end
