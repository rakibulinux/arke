class CreateBalances < ActiveRecord::Migration[5.2]
  def change
    create_table :balances do |t|
      t.references :credential, foreign_key: true
      t.string :currency
      t.decimal :amount
      t.decimal :available
      t.decimal :locked

      t.timestamps
    end
  end
end
