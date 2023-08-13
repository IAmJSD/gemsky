class CreateUserEmailUpdateRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :user_email_update_requests do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :email, null: false
      t.string :token, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
