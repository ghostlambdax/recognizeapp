class CreateCatalogs < ActiveRecord::Migration[5.0]
  def change
    create_table :catalogs do |t|
      t.string :currency
      t.decimal :points_to_currency_ratio, precision: 10, scale: 2, default: 1
      t.boolean :is_enabled, default: false
      t.references :company, foreign_key: true

      t.timestamps
    end
  end
end
