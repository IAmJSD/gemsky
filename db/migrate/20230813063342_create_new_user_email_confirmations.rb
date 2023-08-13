class CreateNewUserEmailConfirmations < ActiveRecord::Migration[7.0]
  def change
    create_table :new_user_email_confirmations do |t|

      t.timestamps
    end
  end
end
