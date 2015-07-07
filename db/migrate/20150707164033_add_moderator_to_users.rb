class AddModeratorToUsers < ActiveRecord::Migration
  def change
    add_column :users, :moderator, :boolean, null: false, default: false
    add_index :users, :moderator
  end
end
