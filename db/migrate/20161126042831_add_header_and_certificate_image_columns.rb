class AddHeaderAndCertificateImageColumns < ActiveRecord::Migration[4.2]
  def change
    add_column :company_customizations, :header_logo, :string
    add_column :company_customizations, :certificate_background, :string
  end
end
