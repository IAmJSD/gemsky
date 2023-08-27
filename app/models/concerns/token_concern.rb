module TokenConcern
    extend ActiveSupport::Concern

    included do
        before_create :generate_token

        def self.token_ttl=(ttl)
            @token_ttl = ttl
        end

        def self.token_ttl
            @token_ttl
        end

        def self.token_wraps=(name)
            @token_wraps = name
        end

        def self.token_wraps
            @token_wraps
        end

        def self.return_full_token
            @return_full_token = true
        end

        def self.resolve_token!(token)
            # Find the token.
            x = self.find_by!(token: token)

            # If a TTL is present, check if it is expired.
            if self.token_ttl.present?
                plus_ttl = x.updated_at + self.token_ttl
                if plus_ttl < Time.now
                    # Delete the record and return a error.
                    x.destroy
                    raise ActiveRecord::RecordNotFound
                end
            end

            # Touch the record and return the wrapped value.
            self.transaction do
                x.touch
            end
            @return_full_token ? x : x.send(self.token_wraps)
        end

        def self.resolve_token(token)
            self.resolve_token!(token)
        rescue ActiveRecord::RecordNotFound
            nil
        end

        def self.belongs_to(name, scope = nil, **options)
            self.token_wraps = name if self.token_wraps.nil?
            super(name, scope, **options)
        end

        private

        def generate_token
            self.token = SecureRandom.hex(20) if token.nil?
        end
    end
end
