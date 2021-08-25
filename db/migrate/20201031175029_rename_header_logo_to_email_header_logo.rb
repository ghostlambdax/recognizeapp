class RenameHeaderLogoToEmailHeaderLogo < ActiveRecord::Migration[5.0]
  def change
    rename_column :company_customizations, :header_logo, :email_header_logo
  end
end
