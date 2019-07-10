class CreateMarkets < ActiveRecord::Migration[5.2]
  def change
    create_table :markets do |t|
      t.references :exchange, foreign_key: true
      t.string :name
      t.string :base
      t.string :quote
      t.integer :base_precision
      t.integer :quote_precision
      t.decimal :min_ask_amount, precision: 32, scale: 16, default: "0.0", null: false
      t.decimal :min_bid_amount, precision: 32, scale: 16, default: "0.0", null: false
      t.string :state

      t.timestamps
    end
  end
end
