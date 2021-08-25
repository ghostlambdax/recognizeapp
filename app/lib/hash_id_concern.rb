module HashIdConcern
  extend ActiveSupport::Concern
  included do
  end

  module ClassMethods
    def find_from_recognize_hashid(hash_id)
      id = Recognize::Application.hasher.decode(hash_id).presence&.first
      self.find(id) if id.present?
    end
  end

  def recognize_hashid
    self.id.present? ? Recognize::Application.hasher.encode(self.id) : nil
  end

  module Finder
    def find(*args)
      param = args.length == 1 ? args.first : args

      param_is_stringified_integer = param.is_a?(String) && param.to_i.to_s == param
      param = param.to_i if param_is_stringified_integer

      case param
      when Integer, Array
        super(param)
      else
        self.find_from_param(param)
      end
    end
  end
end
