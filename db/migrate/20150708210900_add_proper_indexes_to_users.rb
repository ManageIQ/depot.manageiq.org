class AddProperIndexesToUsers < ActiveRecord::Migration
  def change
    add_index :users, :roles_mask
    add_index :users, :email
  end
end
