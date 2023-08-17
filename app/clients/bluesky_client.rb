# frozen_string_literal: true

class BlueskyClient
    def initialize(identifier, token)
        @identifier = identifier
        @token = token
    end

    def get_session
        xrpc_client.get.com_atproto_server_getSession
    end

    private

    def token_outdated?
        return true if @auth_token.nil?
        Time.now > @token_expires_at
    end

    def xrpc_client
        return @xrpc_client unless token_outdated?

        # Check if we should refresh.
        session = nil
        if @auth_token.nil?
            # Get a new token.
            session = XRPC::Client.new('https://bsky.social').post.com_atproto_server_createSession(
                identifier: @identifier,
                password: @token,
            )
        else
            # Refresh the token.
            session = XRPC::Client.new('https://bsky.social', @refresh_token).post.com_atproto_server_refreshSession
        end
        @auth_token = session['accessJwt']
        @refresh_token = session['refreshJwt']
        @token_expires_at = Time.now + 2.minutes
        @xrpc_client = XRPC::Client.new('https://bsky.social', @auth_token)
    end
end
