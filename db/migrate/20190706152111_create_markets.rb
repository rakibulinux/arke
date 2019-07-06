class CreateMarkets < ActiveRecord::Migration[5.2]
  def change
    create_table :markets do |t|
      t.references :exchange, foreign_key: true
      t.string :name
      t.string :base
      t.string :quote
      t.integer :base_precision
      t.integer :quote_precision
      t.string :state

      t.timestamps
    end
  end
end
