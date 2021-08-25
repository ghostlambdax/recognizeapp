class GenerateCatalogForCompanies < ActiveRecord::Migration[5.0]
  def up
    Company.find_each do |company|
      catalog = company.catalogs.create(points_to_currency_ratio: company.points_to_currency_ratio, currency: company.currency, is_enabled: true)
      company.rewards.update_all(catalog_id: catalog.id)
    end
  end

  def down
    Catalog.includes(:company).find_each do |catalog|
      if catalog.company.currency == catalog.currency
        catalog.company.update(points_to_currency_ratio: catalog.points_to_currency_ratio)
      end
    end
  end
end




