class CreateTrades < ActiveRecord::Migration[5.2]
  def change
    create_table :trades do |t|
      t.references :account, foreign_key: true
      t.references :market, foreign_key: true
      t.string :tid
      t.integer :side
      t.decimal :price
      t.decimal :amount
      t.decimal :fee

      t.timestamps
    end
  end
end
