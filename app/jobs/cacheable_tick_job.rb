class CacheableTickJob < ApplicationJob
  queue_as :default

  def perform(cacheable_class_name, slot_class_name, slot_id)
    # Get the slot from the database.
    slot = slot_class_name.constantize.find(slot_id)

    # Return and destroy the reload job if the slot is nil.
    if slot.nil?
      CacheableTickJobItem.where(cacheable_class: cacheable_class_name, slot_class: slot_class_name, slot_id: slot_id).destroy_all
      return
    end

    # Get the cacheable class.
    cacheable_class = cacheable_class_name.constantize

    # Check the reload_every variable.
    reload_every = cacheable_class.instance_variable_get(:@reload_every)
    raise TypeError, "reload_every is unset!" if reload_every.nil?

    # Start a job to re-run ourselves in reload_every.
    job = CacheableTickJob.set(wait: reload_every).perform_later(cacheable_class_name, slot_class_name, slot_id)
    CacheableTickJobItem.where(
      cacheable_class: cacheable_class_name, slot_class: slot_class_name, slot_id: slot_id,
    ).update(job_id: job.provider_job_id)

    # Run the CacheableReloadJob.
    CacheableReloadJob.perform_now(slot, cacheable_class_name)
  end
end
