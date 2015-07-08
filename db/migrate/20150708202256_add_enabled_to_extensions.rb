class AddEnabledToExtensions < ActiveRecord::Migration
  def change
    add_column :extensions, :enabled, :boolean, null: false, default: true
    add_index :extensions, :enabled
  end
end
