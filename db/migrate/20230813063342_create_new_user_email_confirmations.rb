class CreateNewUserEmailConfirmations < ActiveRecord::Migration[7.0]
  def change
    create_table :new_user_email_confirmations do |t|
      t.string :email, null: false, index: true
      t.string :token, null: false, index: { unique: true }

      t.timestamps
    end
  end
end
