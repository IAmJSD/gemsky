class HalfToken < ApplicationRecord
    include TokenConcern

    return_full_token

    belongs_to :user
    self.token_ttl = 15.minutes

    def upgrade!
        t = UserToken.create(user: self.user)
        self.destroy
        t.token
    end
end
