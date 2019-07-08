class RenameCredentialsToAccounts < ActiveRecord::Migration[5.2]
  def change
    rename_table :credentials, :accounts

    remove_column :strategies, :debug
    rename_column :strategies, :frequency, :interval

    remove_reference :balances, :credential
    add_reference :balances, :account, foreign_key: true

    remove_reference :trades,  :credential
    add_reference :trades, :account, foreign_key: true
  end
end
