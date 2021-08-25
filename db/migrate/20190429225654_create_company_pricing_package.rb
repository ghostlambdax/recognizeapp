class CreateCompanyPricingPackage < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :price_package, :string
  end
end
