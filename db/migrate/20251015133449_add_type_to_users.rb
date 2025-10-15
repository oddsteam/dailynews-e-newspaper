class AddTypeToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :type, :string
    add_index :users, :type
  end
end
