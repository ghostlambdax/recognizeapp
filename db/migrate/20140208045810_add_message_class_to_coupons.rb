class AddMessageClassToCoupons < ActiveRecord::Migration[4.2]
  def change
    add_column :coupons, :css_class, :string
  end
end
