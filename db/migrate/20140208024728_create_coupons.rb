class CreateCoupons < ActiveRecord::Migration[4.2]
  def change
    create_table :coupons do |t|
      t.string :code
      t.text :message
      t.text :stripe_data
      t.datetime :deleted_at
    end
  end
end
