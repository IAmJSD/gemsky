class CreateUserPasswordChangeRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :user_password_change_requests do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :token, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
