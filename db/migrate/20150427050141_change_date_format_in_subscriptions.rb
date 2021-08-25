class ChangeDateFormatInSubscriptions < ActiveRecord::Migration[4.2]
	def up
	   	change_column :subscriptions, :invoice_date, :date
	end

	def down
		change_column :subscriptions, :invoice_date, :datetime
	end
end
