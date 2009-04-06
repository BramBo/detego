class CreateConnectors < ActiveRecord::Migration
  def self.up
    create_table :connectors do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :connectors
  end
end
