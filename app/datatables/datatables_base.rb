class DatatablesBase
  include GlobalID::Identification

  attr_reader :view, :company
  delegate :params, :h, :link_to, :humanized_money_with_symbol, :current_user, to: :@view

  def self.find(serialized_json_datatable)
    datatable_hash = JSON.parse(serialized_json_datatable)
    # The incoming hash likely hash _hash[:view].params which is
    # ActionController::Parameters which you can't call .to_hash (for security)
    # So pass it through and let SerializableViewPresenter handle it
    # But we still need to be sure about the keys - whether they a string
    # or symbol
    # This we will manually handle here. We don't wrap with HashWithIndifferentAccess
    # because that will end up calling .to_hash which is deprecated on ActionController::Parameters
    view = SerializableViewPresenter.from_h(datatable_hash[:view] || datatable_hash["view"])
    company = Company.find(datatable_hash[:company_id] || datatable_hash["company_id"])
    user = User.find_by(id: datatable_hash[:user_id] || datatable_hash["user_id"])
    # FIXME: stub implementation - need to make this more generic
    if datatable_hash.key?("report")
      report = ::Report::Recognition.find(datatable_hash["report"])
      self.new(view, company, report)
    elsif user.present?
      self.new(view, user)
    else
      self.new(view, company)
    end
  end

  def initialize(view, company)
    @view = view
    @company = company
  end

  def id
    self.serialize_to_hash.to_json
  end

  def serialize_to_hash
    {
      "view" => self.serializeable_view_presenter.to_h,
      "company_id" => self.company.id
    }
  end

  def all_records
    raise "Must be implemented by subclass"
  end

  def all_records_filtered_by_date_range(table:)
    set = all_records
    if date_range
      set = set.where(table => { created_at: date_range.range })
    end
    set
  end

  def allow_export
    # FIXME: do we want this to default to false, and force opt in?
    true
  end

  def allow_search
    true
  end

  def as_json(options = {})
    {
      recordsTotal: all_records.size,
      recordsFiltered: records.total_entries,
      data: data
    }
  end

  def column_attributes
    @column_attributes ||= begin
      ca = self.class.const_defined?("COLUMN_ATTRIBUTES") ?
        self.class.const_get("COLUMN_ATTRIBUTES").deep_dup :
        {}

      column_exclusions.each do |ce|
        i = column_table_map.keys.index(ce)
        ca[i] ||= {}
        ca[i][:visible] = false
      end

      ca
    end.freeze
  end

  def column_exclusions
    []
  end

  def colvis_options
    {}
  end

  def date_range
    return nil unless params[:from].present? && params[:to].present?
    @date_range ||= DateRange.new(params[:from], params[:to])
  end

  def disable_attribute_escaping
    @disable_attribute_escaping = true
  end

  # subclasses can customize this
  def export_filename
    self.namespace
  end

  # subclasses should override this if they have
  # child row data
  def group_rows?
    false
  end

  def columns
    raise "Must be implemented by subclass"
  end

  def column_table_map
    raise "Must be implemented by subclass"
  end

  def column_count
    columns.length - column_attributes.select{|k,v| v.has_key?(:visible) && !v[:visible]}.length
  end

  def data
    records.map do |record|
      row(record)
    end
  end

  # default sorting
  # first column is usually date that you want descending
  def default_order
    "[[ 0, \"desc\" ]]"
  end

  def filters
    []
  end

  def filtered_records
    raise "Must be implemented by subclass"
  end

  # used by `filtered_records` method in child classes
  def filtered_set(set, search_term, search_columns)
    # split search terms separated by spaces, which may be grouped by quotes (eg. <foo "bar baz"> => ["foo", "bar baz"])
    tokens = search_term.strip.scan(/("[^"]+"|\w+)\s*/)
    tokens = tokens.flatten.map{|t| t.delete('"') }

    tokens.each do |token|
      condition_strs = search_columns.map { |column| "#{column} like :search" }
      set = set.where(condition_strs.join(" OR "), search: "%#{token}%")
    end
    set
  end

  def manager_admin_table?
    self.class.to_s.split(':').first === "ManagerAdmin"
  end

  def disable_paging!
    @disable_paging = true
  end

  def log_debug!
    str = "Debug Datatable(copyable into terminal): "
    str << "\n\thash = #{self.id}"
    str << "\n\tdatatable = DatatablesBase.find(hash)"

    Rails.logger.debug str
  end

  def paging
    # can be overridden by subclass
    return !@disable_paging if defined?(@disable_paging)
    true
  end

  def page
    # This, along with the guard at per_page
    # manually forces only one page (eg all records)
    # unless the paging flag is true
    return 1 unless paging

    if params[:length].to_i == -1
      1
    else
      params[:start].to_i/per_page + 1
    end
  end

  FIXNUM_MAX = (2**(0.size * 8 -2) -1)
  def per_page
    return all_records.size unless paging

    if params[:length].to_i == -1
      FIXNUM_MAX
    else
      params[:length].to_i > 0 ? params[:length].to_i : 10
    end
  end
  
  def records
    @records ||= filtered_records
  end

  def row(record)
    record_row = serialized_record(record)
    record_row.as_json(root: false)
  end

  def search_query
    params.dig(:search, :value)
  end

  def serializer
    raise "Must be implemented by subclass"
  end

  # allows passing custom args from datatable to serializer
  def custom_serializer_opts
    {}
  end

  def serialized_record(record)
    serializer.new(record, context: view, **custom_serializer_opts).tap do |s|
      # this setter method is only defined when the serializer is a descendant of BaseDatatableSerializer - which is the only case it's needed
      s.try(:disable_attribute_escaping=, true) if @disable_attribute_escaping
    end
  end

  def serializeable_view_presenter
    SerializableViewPresenter.new(view)
  end

  def sort_columns
    sc = columns.values_at(*order_params.map{|p| p["column"].to_i })
    sc.map{|c| column_table_map[c].presence || c}
  end

  def sort_columns_and_directions
    sort_columns.each_with_index.map{|c,i| "#{c} #{sort_directions[i]}"}.join(", ")
  end

  def sort_directions
    order_params.map{|p| p["dir"] }
    # order_params[0][:dir] == "desc" ? "desc" : "asc"
  end

  def server_side_export
    false
  end

  def paginated_set(set)
    set.paginate(page: page, per_page: per_page)
  end

  def include_all_option_in_length_menu
    true
  end

  class BaseFilter
    attr_reader :name, :label

    def initialize(name, label)
      @name = name
      @label = label
    end

    def checkbox?
      false
    end

    def select?
      false
    end

    def row_group?
      false
    end
  end

  class FilterRowGroup < BaseFilter
    attr_reader :filters

    def initialize(*filters)
      @filters = *filters
    end

    def row_group?
      true
    end
  end

  class SelectFilter < BaseFilter
    attr_reader :choices, :opts
    def initialize(name, label, choices, opts = {})
      @choices = choices
      @opts = opts
      super(name, label)
    end

    def selected
      opts[:selected]
    end

    def select?
      true
    end

    def multiple?
      opts[:multiple]
    end

    def html_opts
      hopts = {class: "select2", id: opts[:id]}
      hopts[:multiple] = true if multiple?
      return hopts
    end
  end

  class CheckboxFilter < BaseFilter
    def checkbox?
      true
    end
  end

  private

  def order_params
    # manual whitelisting for nested hash w/ arbitrary keys
    params.require(:order)
          .values
          .select do |h|
            h.keys.sort == %w[column dir] &&
            h.values.all?{ |v| v.is_a? String }
          end
  end
end
