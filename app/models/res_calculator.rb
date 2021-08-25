# frozen_string_literal: true

class ResCalculator

  attr_reader :object, :start_range, :end_range

  METRICS = {
    monthly: ->{1.month.ago},
    quarterly: ->{3.months.ago},
    yearly: ->{1.year.ago}
  }.freeze
  def self.metrics(object, metrics: [:monthly, :quarterly, :yearly])
    metrics.inject({}) do |data, metric|
      start_d = METRICS[metric].call
      end_d = Time.current
      calc = new(object, start_d, end_d)
      data[metric] = {recipient_res: calc.res_score, sender_res: calc.sender_res_score}
      data
    end
  end

  def initialize(object, start_range = 1.month.ago, end_range = Time.current)
    @object = object
    @start_range = start_range
    @end_range = end_range
  end

  def report
    @report ||=  report_class.new(object, start_range, end_range)
  end

  # metro benchmark: 6.98 seconds 5/1/2014
  # new metro bench: 0.27 seconds 5/1/2014
  def res_score
    return 0 if report.users.size == 0
    ((report.unique_recipient_count / report.users.size.to_f) * 100).round(2)
  end

  def sender_res_score
    return 0 if report.users.size == 0
    ((report.unique_sender_count) / report.users.size.to_f * 100).round(2)
  end

  private
  # can work for Team or Company or anything else as long as it 
  # has a report and can respond to #unique_recognition_recipients and #users
  def report_class
    "Report::#{object.class}".constantize
  end
end
