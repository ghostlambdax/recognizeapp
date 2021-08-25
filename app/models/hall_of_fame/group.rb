class HallOfFame::Group
  attr_reader :time_period, :report, :sort_by
  def initialize(time_period, report, opts={})
    @time_period = time_period
    @sort_by = opts[:sort_by] || :received_recognitions
    @report = report
    @user_ids = report.first_place_leaders(sort_by).values.select{|data| data[sort_by] > 0}.map{|data|
      data[:user].id
    } 
  end

  def user_ids
    @user_ids
  end

  def has_winners?
    @user_ids.present?
  end
end
