class BlueskyPreferences < BaseModel
    schema({
        :nsfw => :string, :hate => :string,
        :spam => :string, :gore => :string,
        :impersonation => :string,
        :suggestive => :string,
        :nudity => :string,
        :adult_content => :boolean,
    })

    ACTION_TYPES = %w[hide warn show].freeze
    ATTR_NAMES = [
        :nsfw, :hate, :spam, :gore, :impersonation,
        :suggestive, :nudity,
    ]
    validates_many ATTR_NAMES, inclusion: { in: ACTION_TYPES }, presence: true

    def self.find_by_bluesky_user!(bluesky_user)
        preferences = bluesky_user.bluesky_client.get_preferences
        kwargs = {
            nsfw: 'warn',
            hate: 'warn',
            spam: 'warn',
            gore: 'warn',
            impersonation: 'warn',
            suggestive: 'warn',
            nudity: 'warn',
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
        self.assign_attributes(**kwargs)
        return false unless self.valid?

        @bluesky_user.bluesky_client.put_preferences(self.build_preferences_body)
        true
    end

    private

    # Builds the body to send to Bluesky because it is needlessly complex.
    def build_preferences_body
        put_opts = [
            {:$type => 'app.bsky.actor.defs#adultContentPref', enabled: self.adult_content},
        ]
        ATTR_NAMES.each do |attr_name|
            put_opts << {
                :$type => 'app.bsky.actor.defs#contentLabelPref',
                label: attr_name.to_s,
                visibility: self.send(attr_name),
            }
        end
        put_opts
    end
end
