class HomeFeedCacheable < BaseCacheable
    cache_for_each :bluesky_user
    reload_every 5.minutes
    reload_after_use

    def should_cache?
        bluesky_user.any_editor_used_after? 12.hours.ago
    end

    def load_resource
        bluesky_user.bluesky_client.get_timeline
    end
end
