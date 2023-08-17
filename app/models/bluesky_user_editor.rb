class BlueskyUserEditor < ApplicationRecord
  belongs_to :user
  belongs_to :bluesky_user
  validates :user, uniqueness: { scope: :bluesky_user_id }

  def owner?
    self.bluesky_user.user == self.user
  end
end
