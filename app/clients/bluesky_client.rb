# frozen_string_literal: true

# All anonymous methods are class methods.
class BlueskyClient
    DID = /^did:[a-z]+:[a-zA-Z0-9._:%-]*[a-zA-Z0-9._-]$/i

    def initialize(identifier, token)
        @identifier = identifier
        @token = token
    end

    def get_session
        xrpc_client.get.com_atproto_server_getSession
    end

    def get_profile(did: nil)
        did = @identifier if did.nil?
        xrpc_client.get.app_bsky_actor_getProfile(actor: did)
    end

    def get_profiles(*dids)
        xrpc_client.get.app_bsky_actor_getProfiles(actors: dids)
    end

    def get_notification_unread_count
        xrpc_client.get.app_bsky_notification_getUnreadCount['count']
    end

    def self.resolve_handle(handle)
        return handle if handle.match?(DID)
        anonymous_xrpc_client.get.com_atproto_identity_resolveHandle(handle: handle)['did']
    end

    def get_post_thread(uri)
        xrpc_client.get.app_bsky_feed_getPostThread(uri: uri)
    end

    private

    def token_outdated?
        return true if @auth_token.nil?
        Time.now > @token_expires_at
    end

    def self.anonymous_xrpc_client
        XrpcClient.new('https://bsky.social')
    end

    def xrpc_client
        return @xrpc_client unless token_outdated?

        # Check if we should refresh.
        s = nil
        if @auth_token.nil?
            # Get a new token.
            s = XrpcClient.new('https://bsky.social').post.com_atproto_server_createSession(
                identifier: @identifier,
                password: @token,
            )
        else
            # Refresh the token.
            s = XrpcClient.new('https://bsky.social', @refresh_token).post.com_atproto_server_refreshSession
        end
        @auth_token = s['accessJwt']
        @refresh_token = s['refreshJwt']
        @token_expires_at = Time.now + 2.minutes
        @xrpc_client = XrpcClient.new('https://bsky.social', @auth_token)
    end
end
