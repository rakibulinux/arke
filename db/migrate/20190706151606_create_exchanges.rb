class CreateExchanges < ActiveRecord::Migration[5.2]
  def change
    create_table :exchanges do |t|
      t.string :name
      t.string :url
      t.string :rest
      t.string :ws
      t.decimal :rate

      t.timestamps
    end
  end
end
