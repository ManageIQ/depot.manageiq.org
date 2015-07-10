class AddLineCountsToExtensionVersions < ActiveRecord::Migration
  def change
    add_column :extension_versions, :rb_line_count, :integer, default: 0, null: false
    add_column :extension_versions, :yml_line_count, :integer, default: 0, null: false
  end
end
