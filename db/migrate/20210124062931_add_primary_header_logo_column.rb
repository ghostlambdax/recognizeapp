class AddPrimaryHeaderLogoColumn < ActiveRecord::Migration[5.0]
  def change
    add_column :company_customizations, :primary_header_logo, :string
    add_column :company_customizations, :secondary_header_logo, :string
  end
end
