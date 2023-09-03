class CacheableReloadJob < ApplicationJob
  queue_as :default

  def perform(slot, cacheable_class_name)
    # Get the cacheable class and initialize it.
    instance = cacheable_class_name.constantize.new(slot)

    # Check if should_cache? is set. If not, make it true.
    should_cache = instance.respond_to?(:should_cache?) ? instance.should_cache? : true

    # Return if we shouldn't cache.
    return unless should_cache

    # Load the resource.
    value = instance.load_resource

    # Cache the value.
    slot = instance.instance_variable_get(:@slot)
    cache_key = "#{instance.class.name}:#{slot.class.name}:#{slot.id}"
    Rails.cache.write(cache_key, value, expires_in: instance.class.instance_variable_get(:@reload_every))
  end
end
