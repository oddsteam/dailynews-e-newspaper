class ChangeCartIdNullableInCartItems < ActiveRecord::Migration[8.1]
  def change
    change_column_null :cart_items, :cart_id, true
  end
end
