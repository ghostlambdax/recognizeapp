class ChangeDefaultValueOfFewPrivacySettingsOfCompanyAndRecognition < ActiveRecord::Migration[5.0]
  def change
    change_column_default :companies, :private_user_profiles, from: false, to: true
    change_column_default :companies, :global_privacy, from: false, to: true
    change_column_default :recognitions, :is_public_to_world, from: true, to: false
  end
end
