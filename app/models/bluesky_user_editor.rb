class BlueskyUserEditor < ApplicationRecord
  belongs_to :user
  belongs_to :bluesky_user
  validates :user, uniqueness: { scope: :bluesky_user_id }
  before_destroy :ensure_owner_remains!

  private

  def is_owner?
    bluesky_user.user_id == user_id
  end

  def ensure_owner_remains!
    errors.add(:base, 'Cannot remove the owner of a Bluesky user.') if is_owner?
  end
end
