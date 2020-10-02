class VisualizationsTagsMigration < Sequel::Migration

  def up
    SequelRails.connection.run('
      ALTER TABLE "visualizations"
      ADD COLUMN tags text[]
    ')
  end # up

  def down
    drop_column :visualizations, :tags
  end # down

end # VisualizationsTagsMigration
