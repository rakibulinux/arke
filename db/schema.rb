# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_07_06_160041) do

  create_table "balances", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "credential_id"
    t.string "currency"
    t.decimal "amount", precision: 10
    t.decimal "available", precision: 10
    t.decimal "locked", precision: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["credential_id"], name: "index_balances_on_credential_id"
  end

  create_table "credentials", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "exchange_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exchange_id"], name: "index_credentials_on_exchange_id"
    t.index ["user_id"], name: "index_credentials_on_user_id"
  end

  create_table "exchanges", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "url"
    t.string "rest"
    t.string "ws"
    t.decimal "rate", precision: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "markets", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "exchange_id"
    t.string "name"
    t.string "base"
    t.string "quote"
    t.integer "base_precision"
    t.integer "quote_precision"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exchange_id"], name: "index_markets_on_exchange_id"
  end

  create_table "strategies", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "source_id"
    t.bigint "target_id"
    t.string "name"
    t.string "driver"
    t.integer "frequency"
    t.json "params"
    t.string "state"
    t.boolean "debug"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_strategies_on_user_id"
  end

  create_table "tickers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "market_id"
    t.decimal "mid", precision: 10
    t.decimal "bid", precision: 10
    t.decimal "ask", precision: 10
    t.decimal "last", precision: 10
    t.decimal "low", precision: 10
    t.decimal "high", precision: 10
    t.decimal "volume", precision: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["market_id"], name: "index_tickers_on_market_id"
  end

  create_table "trades", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "credential_id"
    t.bigint "market_id"
    t.string "tid"
    t.integer "side"
    t.decimal "price", precision: 10
    t.decimal "amount", precision: 10
    t.decimal "fee", precision: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["credential_id"], name: "index_trades_on_credential_id"
    t.index ["market_id"], name: "index_trades_on_market_id"
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "uid", limit: 12
    t.string "email"
    t.integer "level"
    t.string "role"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  add_foreign_key "balances", "credentials"
  add_foreign_key "credentials", "exchanges"
  add_foreign_key "credentials", "users"
  add_foreign_key "markets", "exchanges"
  add_foreign_key "strategies", "users"
  add_foreign_key "tickers", "markets"
  add_foreign_key "trades", "credentials"
  add_foreign_key "trades", "markets"
end
