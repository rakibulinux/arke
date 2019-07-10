class CreateStrategies < ActiveRecord::Migration[5.2]
  def change
    create_table :strategies do |t|
      t.references :user, foreign_key: true
      t.bigint :source_market_id
      t.bigint :source_id
      t.bigint :target_market_id
      t.bigint :target_id
      t.string :name
      t.string :driver
      t.integer :interval
      t.json :params
      t.string :state

      t.timestamps
    end
  end
end
