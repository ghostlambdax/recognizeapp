class FixForCompanyRecognitionCounterCache < ActiveRecord::Migration[4.2]
  def up
    # Company.unscoped.each{|c| Company.unscoped.reset_counters(c.id, :received_recognitions)}
    #Recognition.unscoped.each{|r| r.send(:update_user_recognitions_counter_cache)}
  end

  def down
  end
end
