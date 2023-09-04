class BlueskyPreferences
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::API
    extend ActiveModel::Callbacks

    attribute :nsfw, :string
    attribute :hate, :string
    attribute :spam, :string
    attribute :gore, :string
    attribute :impersonation, :string
    attribute :adult_content, :boolean

    ACTION_TYPES = %w[hide warn show].freeze
    validates :nsfw, inclusion: { in: ACTION_TYPES }, presence: true
    validates :hate, inclusion: { in: ACTION_TYPES }, presence: true
    validates :spam, inclusion: { in: ACTION_TYPES }, presence: true
    validates :gore, inclusion: { in: ACTION_TYPES }, presence: true
    validates :impersonation, inclusion: { in: ACTION_TYPES }, presence: true

    def self.find_by_bluesky_user(bluesky_user)
        preferences = bluesky_user.bluesky_client.get_preferences
        kwargs = {
            nsfw: 'warn',
            hate: 'warn',
            spam: 'warn',
            gore: 'warn',
            impersonation: 'warn',
            adult_content: false,
        }
        preferences[:preferences].each do |preference|
            if preference[:$type] == 'app.bsky.actor.defs#adultContentPref'
                kwargs[:adult_content] = preference[:enabled]
            elsif preference[:$type] == 'app.bsky.actor.defs#contentLabelPref'
                kwargs[preference[:label].to_sym] = preference[:visibility]
            end
        end
        v = new(**kwargs)
        v.instance_variable_set(:@bluesky_user, bluesky_user)
        v
    end

    def update(**kwargs)
        # Update the attributes.
    end
end
