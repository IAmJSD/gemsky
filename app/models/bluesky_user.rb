class BlueskyUser < ApplicationRecord
    belongs_to :user

    validates :token, presence: true # We don't need to uniqueness check since the DID will be unique.
    before_validation :set_did
    validates :identifier, presence: true
    validates :did, presence: true, uniqueness: true

    def identifier
        return @identifier unless @identifier.nil?
        self.did
    end

    def identifier=(identifier)
        @identifier = identifier
    end

    def regenerate_bluesky_client!
        client = BlueskyClient.new(self.did, self.token)
        self.bluesky_client_marshalled = Base64.encode64(Marshal.dump(client))
    end

    def bluesky_client
        BlueskyCallWrapper.new(self)
    end

    private

    class BlueskyCallWrapper
        def initialize(model_instance)
            @model_instance = model_instance
        end

        def method_missing(method, *args, &block)
            self.do_request!(method, *args, &block)
        rescue
            # Remake the client.
            @model_instance.regenerate_bluesky_client!

            # Try again.
            self.do_request!(method, *args, &block)
        end

        private

        def client
            # If it exists, unmarshal it.
            unless @model_instance.bluesky_client_marshalled.nil?
               return Marshal.load(Base64.decode64(@model_instance.bluesky_client_marshalled))
            end

            # Call the method to make a new one on the model instance.
            @model_instance.regenerate_bluesky_client!

            # Recall this method.
            self.client
        end

        def do_request!(method, *args, &block)
            # Send the method to the client.
            new_client = self.client
            res = new_client.send(method, *args, &block)

            # Remarshal the client since information in it may have changed.
            @model_instance.bluesky_client_marshalled = Base64.encode64(Marshal.dump(new_client))

            # Save the model instance.
            @model_instance.save!

            # Return the result.
            res
        end
    end

    def set_did
        if self.did.nil?
            # Will error anyway because of the token uniqueness check.
            return if self.token.nil? || self.identifier.nil?

            # Get the DID.
            begin
                self.did = BlueskyClient.new(self.identifier, self.token).get_session['did']
            rescue
                self.did = nil
            end
        end
    end
end
