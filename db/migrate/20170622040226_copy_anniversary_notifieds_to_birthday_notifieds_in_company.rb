class CopyAnniversaryNotifiedsToBirthdayNotifiedsInCompany < ActiveRecord::Migration[4.2]
  def change
    # data migration only, dont run on init
    if Company.count > 0
      sql = "UPDATE companies SET birthday_notifieds = anniversary_notifieds"
      ActiveRecord::Base.connection.execute(sql)
    end
  end
end
