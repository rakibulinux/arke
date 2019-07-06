class CreateStrategies < ActiveRecord::Migration[5.2]
  def change
    create_table :strategies do |t|
      t.references :user, foreign_key: true
      t.bigint :source_id
      t.bigint :target_id
      t.string :name
      t.string :driver
      t.integer :frequency
      t.json :params
      t.string :state
      t.boolean :debug

      t.timestamps
    end
  end
end
