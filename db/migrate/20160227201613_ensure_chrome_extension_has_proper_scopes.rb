class EnsureChromeExtensionHasProperScopes < ActiveRecord::Migration[4.2]
  def up
    application = Doorkeeper::Application.where(id: 1).first
    if application
      application.update_column(:scopes, "profile read write")
      Doorkeeper::AccessToken.where(application_id: 1).update_all("scopes = 'profile read write'")
    end
  end
end
