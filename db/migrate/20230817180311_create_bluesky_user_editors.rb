class CreateBlueskyUserEditors < ActiveRecord::Migration[7.0]
  def change
    create_table :bluesky_user_editors do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :bluesky_user, null: false, foreign_key: true, index: true

      t.timestamps

      t.index [:user_id, :bluesky_user_id], unique: true
    end
  end
end
