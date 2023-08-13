class CreateIndexOnHalfTokenUsers < ActiveRecord::Migration[7.0]
  def change
    add_index :users, :half_token
  end
end
