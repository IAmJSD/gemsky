class CreateCacheableTickJobItems < ActiveRecord::Migration[7.0]
  def change
    create_table :cacheable_tick_job_items do |t|
      t.string :cacheable_class, null: false
      t.string :slot_class, null: false
      t.integer :slot_id, null: false
      t.string :job_id, null: false

      t.timestamps
      t.index [:cacheable_class, :slot_class, :slot_id], unique: true, name: "cacheable_tick_job_items_unique"
    end
  end
end
