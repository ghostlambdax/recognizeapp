module UsersUrlConcern
  extend ActiveSupport::Concern
  included do
    helper_method :user_path, :user_url if respond_to? (:helper_method)
  end

  def user_path(*args)
    obj = args[0]
    if obj.kind_of?(User)
      opts = {network: obj.network}
      opts.merge!(args[1]) if args[1].kind_of?(Hash)
      super(obj.slug, opts)
    else
      super
    end
  end


  def user_url(*args)
    obj = args[0]
    if obj.kind_of?(User)
      opts = {network: obj.network}
      opts.merge!(args[1]) if args[1].kind_of?(Hash)
      super(obj.slug, opts)
    else
      super
    end
  end
end