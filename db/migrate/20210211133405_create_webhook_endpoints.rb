class CreateWebhookEndpoints < ActiveRecord::Migration[5.0]
  def change
    create_table :webhook_endpoints do |t|
      t.text :target_url, null: false

      t.string :authentication_token
      # POST is the standard method for webhooks
      t.string :request_method, null: false, default: 'POST'
      t.string :request_headers
      t.string :subscribed_event, null: false

      t.text :payload_template

      t.boolean :is_active, default: true

      t.references :owner, foreign_key: { to_table: :users }
      t.references :company, foreign_key: true

      t.timestamps
    end
  end
end
