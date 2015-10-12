class AddOwnerNameToExtensions < ActiveRecord::Migration
  def change
    add_column :extensions, :owner_name, :string
    add_index :extensions, :owner_name
  end
end
