class CreateSignupRequests < ActiveRecord::Migration[4.2]
  def change
    create_table :signup_requests do |t|
      t.string :email
      t.string :pricing

      t.timestamps
    end
  end
end
