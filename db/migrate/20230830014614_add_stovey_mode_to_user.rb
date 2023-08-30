class AddStoveyModeToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :stovey_mode, :boolean
  end
end
