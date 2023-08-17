# frozen_string_literal: true

class BlueskyError < StandardError
    def initialize(error, message)
        super("#{error}: #{message}")
        @error = error
        @message = message
    end

    attr_reader :error, :message
end

class BlueskyClient
    def initialize(identifier, token)
        @identifier = identifier
        @token = token
    end

    def get_session
        get.com_atproto_server_getSession
    end

    private

    def get
        ErrorHandlerWrapper.new(xrpc_client.get)
    end

    def post
        ErrorHandlerWrapper.new(xrpc_client.post)
    end

    def token_outdated?
        return true if @auth_token.nil?
        Time.now > @token_expires_at
    end

    def xrpc_client
        return @xrpc_client unless token_outdated?

        # Check if we should refresh.
        s = nil
        if @auth_token.nil?
            # Get a new token.
            s = XRPC::Client.new('https://bsky.social').post.com_atproto_server_createSession(
                identifier: @identifier,
                password: @token,
            )
        else
            # Refresh the token.
            s = XRPC::Client.new('https://bsky.social', @refresh_token).post.com_atproto_server_refreshSession
        end
        @auth_token = s['accessJwt']
        @refresh_token = s['refreshJwt']
        @token_expires_at = Time.now + 2.minutes
        @xrpc_client = XRPC::Client.new('https://bsky.social', @auth_token)
    end
end

class ErrorHandlerWrapper
    def initialize(client)
        @client = client
    end

    def method_missing(method, *args, **kwargs, &block)
        x = @client.send(method, *args, **kwargs, &block)
        return x if x['error'].nil?
        raise BlueskyError.new(x['error'], x['message'])
    end
end
