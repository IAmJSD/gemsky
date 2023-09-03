class BaseCacheable
    def self.cache_for_each(model_name)
        @cache_for_each = model_name
    end

    def self.reload_every(duration)
        @reload_every = duration
    end

    def self.reload_after_use
        @reload_after_use = true
    end

    def self.reload_after_use?
        @reload_after_use || false
    end

    def initialize(slot)
        # Handle if cache_for_each is unset.
        slot_key = self.class.instance_variable_get(:@cache_for_each)
        raise TypeError, "cache_for_each is unset!" if slot_key.nil?

        # Set slot to a slot value.
        @slot = slot

        # Make a method for the slot key to return the slot on this instance.
        self.define_singleton_method(slot_key) do
            @slot
        end

        # Make sure that load_resource is defined as a instance method.
        raise TypeError, "load_resource is not defined!" unless self.respond_to?(:load_resource)
    end

    def self.load_tickers
        # Check both cache_for_each and reload_every are set.
        cache_for_each = self.instance_variable_get(:@cache_for_each)
        return if cache_for_each.nil?
        reload_every = self.instance_variable_get(:@reload_every)
        return if reload_every.nil?

        # Get the class of the model specified. cache_for_each is a snake case
        # non-pluralized model name.
        model_class = cache_for_each.to_s.classify.constantize

        # In development, drop all CacheableTickJobItems for this class.
        if Rails.env.development?
            CacheableTickJobItem.where(cacheable_class: self.name).destroy_all
        end

        # Go through each model.
        model_class.find_each do |model|
            # Check if there is a CacheableTickJob for this.
            exists = CacheableTickJobItem.where(
                cacheable_class: self.name, slot_class: model_class.name,
                slot_id: model.id,
            ).exists?
            next if exists

            # Create a CacheableTickJob for this.
            job = CacheableTickJob.set(wait: 2.seconds).perform_later(
                self.name, model_class.name, model.id,
            )
            CacheableTickJobItem.create!(
                cacheable_class: self.name, slot_class: model_class.name,
                slot_id: model.id, job_id: job.provider_job_id,
            )
        end
    end

    def self.get(slot)
        instance = self.new(slot)

        # Check if should_cache? is set. If not, make it true.
        should_cache = instance.respond_to?(:should_cache?) ? instance.should_cache? : true

        # Return load_resource here if we shouldn't cache.
        return instance.load_resource unless should_cache

        # Use the Rails caching method.
        value = Rails.cache.fetch("#{self.name}:#{slot.class.name}:#{slot.id}")
        if value.present?
            # Log that we got a cache hit.
            Rails.logger.info("Cache hit for #{self.name}:#{slot.class.name}:#{slot.id}!")

            if self.reload_after_use?
                # If reload_after_use was set, start a job to reload the cache.
                CacheableReloadJob.perform_later(slot, self.name)
            end

            # Return the value.
            return value
        end

        # Cache miss :( - load the resource.
        value = instance.load_resource

        # Cache the value.
        Rails.cache.write("#{self.name}:#{slot.class.name}:#{slot.id}", value, expires_in: self.instance_variable_get(:@reload_every))

        # Return the value.
        value
    end

    def self.purge(slot)
        Rails.cache.delete("#{self.name}:#{slot.class.name}:#{slot.id}")
    end
end
