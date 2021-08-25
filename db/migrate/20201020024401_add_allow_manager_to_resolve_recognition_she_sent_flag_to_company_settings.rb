class AddAllowManagerToResolveRecognitionSheSentFlagToCompanySettings < ActiveRecord::Migration[5.0]
  def change
    add_column :company_settings, :allow_manager_to_resolve_recognition_she_sent, :boolean, default: true
  end
end
