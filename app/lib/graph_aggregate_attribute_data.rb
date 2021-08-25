#GraphAggregateAttributeData.load(Redemption.approved.where(created_at: Time.current.beginning_of_year..Time.current), :weekly).to_array.map{|a| [Time.at(a[0]/1000.0), a[1].to_f]}
class GraphAggregateAttributeData < GraphData
  def self.load(data, interval, aggregate_statement)
    return new([]) unless data.size > 0
    klass = data.respond_to?(:limit) ? data.limit(1).first.class : data[0].class
    table = klass.table_name
    if data.respond_to?(:pluck)
      set = data.except(:select).select("distinct YEARWEEK(#{table}.created_at, #{YEARWEEK_MODE}) as date, #{aggregate_statement}").group("YEARWEEK(#{table}.created_at, #{YEARWEEK_MODE})").order("#{table}.created_at desc")
    else
      ids = data.map(&:id)
      set = klass.where(id: ids).select("distinct YEARWEEK(#{table}.created_at, #{YEARWEEK_MODE}) as date, #{aggregate_statement}").group("YEARWEEK(#{table}.created_at, #{YEARWEEK_MODE})").order("created_at desc")
    end
    new(set, interval: interval)
  end  
end
