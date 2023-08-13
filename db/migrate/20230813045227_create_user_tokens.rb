class CreateUserTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :user_tokens do |t|
      t.string :token, null: false, index: { unique: true }
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
