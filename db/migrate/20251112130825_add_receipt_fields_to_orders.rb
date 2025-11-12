class AddReceiptFieldsToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :paid_at, :datetime
    add_column :orders, :receipt_number, :string
    add_column :orders, :receipt_sent_at, :datetime
  end
end
