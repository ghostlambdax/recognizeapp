class AddProgramEnabledColumnToCompanies < ActiveRecord::Migration[5.0]
  def change
    add_column :companies, :program_enabled, :boolean, default: true
  end
end
