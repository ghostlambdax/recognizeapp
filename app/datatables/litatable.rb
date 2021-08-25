#
#
#
#   )..(                 
#   (.o)  
# `.(  )       
#   ||||    LitaTables
#   "`'"
# 
class Litatable < DatatablesBase

  def initialize(view, company)
    @view = view
    @company = company
  end

  def column_attributes
    @column_attributes ||= begin
      ca = {}
      column_spec.each_with_index{|col, i| ca[i] ||= col}
      ca
    end
  end

  def column_spec
    self.class.const_get("COLUMN_SPEC").deep_dup.select do |col|
      col.has_key?(:if) ? self.instance_eval(&col[:if]) : true
    end.map do |col|
      possible_name = col[:attribute]

      # NOTE: This code allows for dynamic attribute names
      #       I think this might be used for determining whether
      #       to include employee_id or id as the first column
      #       for users.
      #       The UsersDatatable lists the column name as :first_column
      #       and then implements that method to determine whether the company
      #       is using employee_id or not.
      #
      #       There is an exception for the method :id because
      #       DatatablesBase uses this for GlobalID. So, as such this is forbidden
      #       to use for a dynamic method name - and so we exclude it from 
      #       possibly being dynamic
      attr_name = if respond_to?(possible_name) && possible_name.to_sym != :id
        send(possible_name)
      else
        col[:attribute].to_s
      end

      col[:attribute] = attr_name

      # dynamic titles
      if col[:title].respond_to?(:call)
        col[:title] = self.instance_eval(&col[:title])
      end

      col
    end
  end

  def column_table_map
    @column_table_map ||= begin
      default_table = self.class.to_s.gsub("Datatable", '').downcase
      ctm = column_spec.inject({}) do |hash, col_spec| 
        if col_spec[:orderable]
          sort_column = col_spec[:sort_column].respond_to?(:call) ? self.instance_eval(&col_spec[:sort_column]) : col_spec[:sort_column]
          hash[col_spec[:attribute].to_s] = sort_column || "#{default_table}.#{col_spec[:attribute]}"
        end
        hash
      end
      ctm
    end
  end

  def columns
    # column_names = column_spec.map{|col| respond_to?(col[:attribute]) ? send(col[:attribute]).to_s : col[:attribute].to_s}    
    column_names = column_spec.map{|col| col[:attribute] }
    hide_columns = [] #ui may or may not show this column
    hide_columns << "network" unless company.present? && company.in_family?

    columns = {}
    (column_names - hide_columns).each_with_index{|c,i| columns[i] = c }
    return columns
  end

  def colvis_options
    visible_columns, hidden_columns = column_spec.partition{|col| col[:colvis] != :hide }

    { 
      enabled: true,
      columnsToShowByDefault: visible_columns.map{|col| col[:attribute] }
    }
  end
end
