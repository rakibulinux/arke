class CreateArkeTables < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :uid, limit: 12
      t.string :email
      t.integer :level
      t.string :role
      t.string :state

      t.timestamps
    end
    add_index :users, :uid, unique: true
    add_index :users, :email, unique: true

    create_table :exchanges do |t|
      t.string :name
      t.string :url
      t.string :rest
      t.string :ws
      t.decimal :rate

      t.timestamps
    end

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

    create_table :accounts do |t|
      t.references :user, foreign_key: true
      t.references :exchange, foreign_key: true
      t.string :name

      t.timestamps
    end

    create_table :balances do |t|
      t.references :account, foreign_key: true
      t.string :currency
      t.decimal :amount
      t.decimal :available
      t.decimal :locked

      t.timestamps
    end

    create_table :robots do |t|
      t.references :user, foreign_key: true
      t.string     :name
      t.string     :strategy
      t.json       :params
      t.string     :state
      t.timestamps
    end

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

    create_join_table :accounts, :robots do |t|
      t.string :tag
      t.index [:account_id, :robot_id]
    end
  end
end
