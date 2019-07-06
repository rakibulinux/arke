class CreateCredentials < ActiveRecord::Migration[5.2]
  def change
    create_table :credentials do |t|
      t.references :user, foreign_key: true
      t.references :exchange, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end
