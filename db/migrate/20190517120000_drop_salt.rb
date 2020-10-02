require 'carto/db/migration_helper'

include Carto::Db::MigrationHelper

migration(
  proc do
    run "UPDATE users SET crypted_password = concat('$sha$v=1$$',salt,'$',crypted_password) WHERE salt <> ''"
    drop_column :users, :salt
    drop_column :user_creations, :salt
  end,
  proc do
    add_column :users, :salt, String, null: false, default: ''
    add_column :user_creations, :salt, String, null: false, default: ''
  end
)
