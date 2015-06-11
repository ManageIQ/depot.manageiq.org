class UpdateSupportedPlatformsForManageIq < ActiveRecord::Migration
  def change
    add_column :supported_platforms, :released_on, :date, null: false
    remove_column :supported_platforms, :version_constraint
  end
end
