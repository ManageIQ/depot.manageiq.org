class AddAuthScopeToUsers < ActiveRecord::Migration
  def change
    add_column :users, :auth_scope, :string, null: false, default: ""
  end
end
