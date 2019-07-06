class CreateTickers < ActiveRecord::Migration[5.2]
  def change
    create_table :tickers do |t|
      t.references :market, foreign_key: true
      t.decimal :mid
      t.decimal :bid
      t.decimal :ask
      t.decimal :last
      t.decimal :low
      t.decimal :high
      t.decimal :volume

      t.timestamps
    end
  end
end
