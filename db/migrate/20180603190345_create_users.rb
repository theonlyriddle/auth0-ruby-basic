class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :password_digest
      t.string :auth0_id

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :auth0_id, unique: true
  end
end