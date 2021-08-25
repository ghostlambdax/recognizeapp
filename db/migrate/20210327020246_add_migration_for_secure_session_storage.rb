class AddMigrationForSecureSessionStorage < ActiveRecord::Migration[6.0]
  def up
    # Turned this off because this shouldn't be done during the deployment as it can 
    # take too long and cause a deployment to timeout. SHould be done via a background task
    # if Company.count > 1
    #   ActionDispatch::Session::ActiveRecordStore.session_class.find_each(&:secure!)
    # end
  end
end
