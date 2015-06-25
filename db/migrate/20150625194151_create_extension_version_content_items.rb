class CreateExtensionVersionContentItems < ActiveRecord::Migration
  def change
    create_table :extension_version_content_items do |t|
      t.belongs_to :extension_version, index: true, null: false
      t.string :name, null: false
      t.string :path, null: false
      t.string :item_type, null: false
      t.string :github_url, null: false

      t.timestamps
    end

    add_index :extension_version_content_items, [:extension_version_id, :path], unique: true, name: "evcis_evid_path"
  end
end
