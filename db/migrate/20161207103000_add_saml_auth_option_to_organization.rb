require 'carto/db/migration_helper'

include Carto::Db::MigrationHelper

migration(
  proc do
    alter_table :organizations do
      add_column :auth_saml_configuration, :json, null: false, default: '{}'
    end
  end,
  proc do
    drop_column :organizations, :auth_saml_configuration
  end
)
