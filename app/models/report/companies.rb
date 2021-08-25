# This report will get a segment of (or all) companies
# and provide reporting on it such as total recognitions, recognitions this month, comments this week
# This is first to be used in the admin, but can also be used for departments of companies
# This report will only return a map of the company ids and the reporting counts

# NOTE: if data get's stale, expire via: 
#       Report::Companies.expire_caches!
class Report::Companies
  attr_reader :company_ids, :query, :reports

  def self.all(opts = {})
    new(nil, opts)
  end


  def self.paid(opts = {})
    paid_company_ids = Subscription.current.pluck(:company_id) - self.exclude_ids
    new(paid_company_ids, opts)
  end

  def self.exclude_ids
    @@exclude_ids = Company.where(domain: ["recognizeapp.com", "planet.io", "users"]).pluck(:id)
  end

  def all?
    true#!company_ids.present?
  end

  def initialize(company_ids=nil, opts = {})
    @company_ids = company_ids
    setup_opts(opts)

    # @query = company_ids ? Company.where(id: company_ids) : Company.all
  end

  def finder_query(report)
    finder_query = case report
    when :users
      base = User.where.not(company_id: self.class.exclude_ids)
      all? ? base : base.where(company_id: company_ids)
    when :sent_recognitions
      base = PointActivity.where(activity_type: "recognition_sender").where.not(company_id: self.class.exclude_ids)
      all? ? base : base.where(company_id: company_ids)
    when :received_recognitions
      base = PointActivity.where(activity_type: "recognition_recipient").where.not(company_id: self.class.exclude_ids)
      all? ? base : base.where(company_id: company_ids)
    when :approvals
      base = PointActivity.where(activity_type: "recognition_approval_receiver").where.not(company_id: self.class.exclude_ids)
      all? ? base : base.where(company_id: company_ids)
    when :comments
      base = Comment.joins(:commenter).where.not(users: {company_id: self.class.exclude_ids})
      all? ? base : base.where("users.company_id IN (?)", company_ids)
    when :redemptions
      all? ? Redemption : Redemption.where(redemptions: {company_id: company_ids})
    else
      raise "Didn't find query for: #{report}"
    end
    return finder_query
  end

  # returns map of company => :reports_:interval count (eg, comments_this_month)
  def counts(query, report)
    case report
    when :users
      limit(query, report).group(:company_id).count(:company_id)
    when :sent_recognitions
      limit(query, report).group(:company_id).count(:company_id)
    when :received_recognitions, :approvals, :redemptions
      limit(query, report).group(:company_id).count(:company_id)
    when :comments
      limit(query, report).group(:company_id).count(:company_id)
    else
      raise "Didn't find counts query for: #{report}"
    end
  end

  def limit(query, report)
    query.order("count_company_id #{@order_direction}")
  end

  def companies(opts = {})
    setup_opts(opts.present? ? opts : @opts)
    run
  end

  def setup_opts(opts = {})
    @opts = ActiveSupport::HashWithIndifferentAccess.new(opts)
    @limit = @opts[:limit] || 25
    @order = @opts[:order] || "companies.id"
    @order_direction = @opts[:order_direction] || "desc"
    @search = @opts[:search].presence
  end

  def table(report)
    case report.to_s
    when /recognitions/
      :point_activities
    when /approvals/
      :point_activities
     else
      report.to_s
    end
  end

  INTERVALS = [:total, :two_months_ago, :last_month, :this_month]#, :two_weeks_ago, :last_week, :this_week]
  REPORTS = [:users, :sent_recognitions, :received_recognitions, :approvals, :comments, :redemptions] - [:sent_recognitions]
  REPORT_NAMES = REPORTS.map{|rpt| INTERVALS.map{|i| "#{rpt}_#{i}"}}.flatten
  # calculate all the report variables for all the companies
  # return a structure of {:report_name => {:company_id => count, :company_id2 => count}}
  def reports_by_counts
    # TBD: Cache this method
    @reports_by_counts ||= begin
      rpts = {}
      REPORTS.each do |rpt|
        INTERVALS.each do |interval|
          report_name = "#{rpt}_#{interval}"
          rpts[report_name] = send(report_name)
        end
      end
      rpts
    end
  end

  def run
    company_query = @search.present? ? search_query : Company
    company_query = company_query.where.not(id: self.class.exclude_ids)    
    ordered_companies = if REPORT_NAMES.include?(@order.to_s)
      # cids = self.report_by_counts(@order).keys
      cids = self.reports_by_counts[@order.to_s].keys[0..@limit]
      if cids.present?
        companies = company_query.where(id: cids).order("FIELD(companies.id,#{cids.join(",")})")
      else
        companies = company_query
      end
    else
      companies = company_query.limit(@limit).order("#{@order} #{@order_direction}")
    end

    @company_ids = companies.map(&:id)
    reports_by_counts = self.reports_by_counts

    set = companies.map do |c|
      decorator = CompanyDecorator.new(company: c)
      reports_by_counts.each do |key, data|
        decorator[key] = data[c.id]
      end
      decorator
    end

    return set

  end

  def search_query
    if status = Subscription::STATES.detect{|(k,v)| v.to_s.downcase == @search.to_s.downcase}
      # assume its a scope
      Company.joins(:subscription).where(subscriptions: {status: status[0]})
    else
      Company.where("domain like :search OR name like :search", search: "%#{@search}%")
    end
  end

  class CompanyDecorator < Hashie::Mash
    delegate :id, :domain, to: :company

    def subscription
      company.subscription.try(:status_label)
    end
  end

  def cache_key(rpt, interval)
    "companies-report-#{rpt}-#{interval}"
  end

  def self.expire_caches!
    REPORTS.each do |rpt|
      INTERVALS.each do |interval|
        ck = new.cache_key(rpt, interval)
        Rails.logger.debug "Expiring cache: #{ck}"
        Rails.cache.delete(ck)
      end
    end
  end

  # dynamically define all the possible report methods
  REPORTS.each do |rpt|
    INTERVALS.each do |interval|
      # eg. def comments_this_month
      define_method("#{rpt}_#{interval}") do 
        Rails.cache.fetch(self.cache_key(rpt, interval)) do 
          tbl = table(rpt)
          Rails.logger.debug "Calling #{rpt}_#{interval} on table: #{tbl}"

          query = case interval

          when :total
            finder_query(rpt)        

          when :this_month
            interval_start = Interval.monthly.start
            interval_end = Interval.monthly.end
            finder_query(rpt).where(tbl => {created_at: interval_start..interval_end})        

          when :this_week
            interval_start = Interval.weekly.start
            interval_end = Interval.weekly.end
            finder_query(rpt).where(tbl => {created_at: interval_start..interval_end})        

          when :last_month
            interval_start = Interval.monthly.start(shift: -1)
            interval_end = Interval.monthly.end(shift: -1)
            finder_query(rpt).where(tbl => {created_at: interval_start..interval_end})        

          when :last_week
            interval_start = Interval.weekly.start(shift: -1)
            interval_end = Interval.weekly.end(shift: -1)
            finder_query(rpt).where(tbl => {created_at: interval_start..interval_end})        

          when :two_months_ago
            interval_start = Interval.monthly.start(shift: -2)
            interval_end = Interval.monthly.end(shift: -2)
            finder_query(rpt).where(tbl => {created_at: interval_start..interval_end})        

          when :two_weeks_ago
            interval_start = Interval.weekly.start(shift: -2)
            interval_end = Interval.weekly.end(shift: -2)
            finder_query(rpt).where(tbl => {created_at: interval_start..interval_end})        

          end
          counts = counts(query, rpt)
          counts
        end
      end
    end
  end
end