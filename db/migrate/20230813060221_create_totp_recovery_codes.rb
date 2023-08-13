class CreateTotpRecoveryCodes < ActiveRecord::Migration[7.0]
  def change
    create_table :totp_recovery_codes do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :code

      t.timestamps
    end
  end
end
