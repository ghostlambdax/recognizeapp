class AddApplicationCssImportToExistingCustomStylesheets < ActiveRecord::Migration[6.0]
  def change
    ActiveRecord::Base.connection.execute("UPDATE `company_customizations` SET `company_customizations`.`stylesheet` = CONCAT(`stylesheet`, '@import \"application\";') WHERE `company_customizations`.`stylesheet` IS NOT NULL;")
  end
end
