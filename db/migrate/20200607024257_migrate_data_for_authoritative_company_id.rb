class MigrateDataForAuthoritativeCompanyId < ActiveRecord::Migration[5.0]
  def up
    if Recognition.count > 0
      puts " ------------------- "
      puts "Hi there. We need to update your data to denormalize the authoritative company id on Recognitions"
      puts "Depending on the size of your database this might take a few minutes."
      puts "Please standby... :) "    

      # First handle mistake with RecognitionRecipient's where the join table recipient_company_id is not correct
      # due to moving users across companies
      sub_query = User.with_deleted.select('id, company_id, network').to_sql
      query = "UPDATE recognition_recipients rr INNER JOIN (#{sub_query}) u ON rr.user_id = u.id SET rr.recipient_company_id = u.company_id, rr.recipient_network = u.network"
      Recognition.connection.execute(query)

      # handle all cases where the badge has a company id (custom badges enabled - which is most cases) first
      # This algorithm is gotten from https://github.com/rails/rails/issues/522#issuecomment-426037101
      sub_query = Badge.where.not(company_id: nil).select('id, company_id').to_sql
      query = "UPDATE recognitions r INNER JOIN (#{sub_query}) b ON r.badge_id = b.id SET authoritative_company_id = b.company_id where authoritative_company_id IS NULL"
      Recognition.connection.execute(query)

      # handle system user sender (where badge doesn't have company_id)
      # This will be old anniversary recognitions (Edge case) or ambassador badges
      sub_query = RecognitionRecipient.with_deleted.select('recognition_id, recipient_company_id').to_sql
      query = "UPDATE recognitions r INNER JOIN (#{sub_query}) rr ON rr.recognition_id = r.id SET authoritative_company_id = rr.recipient_company_id where authoritative_company_id IS NULL AND r.sender_id = 1"
      Recognition.connection.execute(query)

      # Get the remaining recognitions which is to set the
      # authoritative to the sender company
      Recognition.where(authoritative_company_id: nil).update_all("authoritative_company_id = sender_company_id")

      # Verify (for manual execution only)
      # data = Recognition.find_each.select{|rec| rec.authoritative_company_id != rec.authoritative_company&.id}
    end
  end
end
