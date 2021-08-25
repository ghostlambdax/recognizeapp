class AddFlagForCompanyToSetPointDollarRatio < ActiveRecord::Migration[4.2]
  def change
    # default is true for new companies
    add_column :companies, :has_set_points_to_dollar_ratio, :boolean, default: true
  end
end
