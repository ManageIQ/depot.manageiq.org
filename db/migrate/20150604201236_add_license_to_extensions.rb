class AddLicenseToExtensions < ActiveRecord::Migration
  def change
    add_column :extensions, :license_name, :string, default: ""
    add_column :extensions, :license_text, :text, default: ""
  end
end
