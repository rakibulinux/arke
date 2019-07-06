class CreateUsers < ActiveRecord::Migration[5.2]
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
  end
end
