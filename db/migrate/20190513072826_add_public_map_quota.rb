require 'carto/db/migration_helper'

include Carto::Db::MigrationHelper

migration(
  proc do
    add_column :users, :public_map_quota, Integer, null: true
  end,
  proc do
    drop_column :users, :public_map_quota
  end
)
