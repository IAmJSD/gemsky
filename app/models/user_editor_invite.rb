class UserEditorInvite < ApplicationRecord
    include TokenConcern

    return_full_token
    self.token_ttl = 1.day

    belongs_to :bluesky_user
    belongs_to :user
    validate :user_is_not_an_editor, on: :create

    after_create :send_invite_email

    def accept!
        # We intentionally ignore the return value here.
        self.bluesky_user.bluesky_user_editors.create(user: self.user)

        self.destroy!
    end

    private

    def user_is_not_an_editor
        return if self.bluesky_user.nil?
        return if self.bluesky_user.bluesky_user_editors.find { |editor| editor.user_id == self.user_id }.nil?
        errors.add(:user, 'is already an editor')
    end

    def send_invite_email
        # Try to convert the DID to a handle.
        handle = self.bluesky_user.did
        begin
          handle = self.bluesky_user.bluesky_client.get_profile['handle']
        rescue BlueskyError
          # Do nothing.
        end

        UserMailer.with(email: self.user.email, handle: handle, token: self.token).user_editor_invite.deliver_later
    end
end
