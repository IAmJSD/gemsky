class AddBlueskyClientMarshalledToBlueskyUser < ActiveRecord::Migration[7.0]
  def change
    add_column :bluesky_users, :bluesky_client_marshalled, :string
  end
end
