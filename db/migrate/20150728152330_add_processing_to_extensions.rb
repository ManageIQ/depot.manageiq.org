class AddProcessingToExtensions < ActiveRecord::Migration
  def change
    add_column :extensions, :syncing, :boolean, default: false, index: true
  end
end
