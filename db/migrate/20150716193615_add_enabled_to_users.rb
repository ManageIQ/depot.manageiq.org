class AddEnabledToUsers < ActiveRecord::Migration
  def change
    add_column :users, :enabled, :boolean, default: true, null: false
  end
end
