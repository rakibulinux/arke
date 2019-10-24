# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_08_03_182417) do

  create_table "accounts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "exchange_id"
    t.string "name"
    t.binary "api_key_encrypted"
    t.binary "api_secret_encrypted"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exchange_id"], name: "index_accounts_on_exchange_id"
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "accounts_robots", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "robot_id", null: false
    t.string "tag"
    t.index ["account_id", "robot_id"], name: "index_accounts_robots_on_account_id_and_robot_id"
  end

  create_table "balances", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "account_id"
    t.string "currency"
    t.decimal "amount", precision: 10
    t.decimal "locked", precision: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_balances_on_account_id"
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
    t.decimal "min_price", precision: 32, scale: 16, default: "0.0", null: false
    t.decimal "min_amount", precision: 32, scale: 16, default: "0.0", null: false
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exchange_id"], name: "index_markets_on_exchange_id"
  end

  create_table "robots", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id"
    t.string "name"
    t.string "strategy"
    t.json "params"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_robots_on_user_id"
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
    t.bigint "account_id"
    t.bigint "market_id"
    t.string "tid"
    t.integer "side"
    t.decimal "price", precision: 10
    t.decimal "amount", precision: 10
    t.decimal "fee", precision: 10
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_trades_on_account_id"
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

  add_foreign_key "accounts", "exchanges"
  add_foreign_key "accounts", "users"
  add_foreign_key "balances", "accounts"
  add_foreign_key "markets", "exchanges"
  add_foreign_key "robots", "users"
  add_foreign_key "tickers", "markets"
  add_foreign_key "trades", "accounts"
  add_foreign_key "trades", "markets"
end
