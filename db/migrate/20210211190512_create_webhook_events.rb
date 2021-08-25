class CreateWebhookEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :webhook_events do |t|
      t.integer :company_id, null: false
      t.string :name, null: false

      t.text :request_payload
      t.text :request_method
      t.text :request_url
      t.text :request_headers

      t.text :response_payload
      t.text :response_headers
      t.text :response_status_code

      t.references :endpoint, foreign_key: { to_table: 'webhook_endpoints' }
    end
  end
end
