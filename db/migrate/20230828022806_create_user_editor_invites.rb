class CreateUserEditorInvites < ActiveRecord::Migration[7.0]
  def change
    create_table :user_editor_invites do |t|
      t.references :bluesky_user, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
