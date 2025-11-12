class AddTaxIdToCompanies < ActiveRecord::Migration[8.1]
  def change
    add_column :companies, :tax_id, :string
  end
end
