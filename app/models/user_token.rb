class UserToken < ApplicationRecord
  include TokenConcern

  belongs_to :user
  self.token_ttl = 7.days
end
