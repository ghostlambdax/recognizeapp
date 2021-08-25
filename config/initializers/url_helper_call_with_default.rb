# affects optimized routes
module UrlHelperCallWithDefault
  def call(t, args, inner_options)
    controller_options = t.url_options
    options = controller_options.merge @options
    modified_inner_options = inner_options || {}
    modified_segment_keys = @segment_keys
    unless modified_inner_options.has_key?(:network)
      modified_segment_keys = modified_segment_keys.select{|x| x!= :network}
      modified_inner_options = modified_inner_options.merge({ :network => nil })
    end
    hash = handle_positional_args(controller_options,
                                  modified_inner_options,
                                  args,
                                  options,
                                  modified_segment_keys)
    if hash.has_key?(:network) && !hash[:network]
      if hash[:id] && hash[:id].kind_of?(ApplicationRecord)
        obj = hash[:id]
        hash[:network] = obj.network if obj.respond_to?(:network)
      else
        if args[0].kind_of?(ApplicationRecord)
          obj = args[0]
          hash[:network] = obj.network if obj.respond_to?(:network)
        end
      end
    end

    # if hash[:network].kind_of?(ActiveRecord::Base)
    #   obj = hash.delete(:network)
    #   # added to handle users links who may be in different subcompany
    #   # Eg, cross-sub-company recognitions
    #   hash[:network] = obj.network if obj.respond_to?(:network)
    #
    #   if hash.has_key?(:id)
    #     hash[:id] = obj
    #   else
    #     # this handles nested resources
    #     obj_key = (obj.class.to_s.underscore+"_id").to_sym
    #     if hash.has_key?(obj_key)
    #       hash[obj_key] = obj
    #     end
    #   end
    # end

    begin
      t._routes.url_for(hash, route_name, url_strategy)
    rescue ActionController::UrlGenerationError => e
      if t.respond_to?(:current_user) && t.current_user && (hash[:network].blank?)
        hash[:network] = t.current_user.network
      elsif hash[:network].blank?
        hash.delete(:network)
      else
        raise e
      end
      t._routes.url_for(hash, route_name, url_strategy)
    end

  end
end
ActionDispatch::Routing::RouteSet::NamedRouteCollection::UrlHelper.prepend(UrlHelperCallWithDefault)