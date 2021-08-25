class ApplicationDecorator < Draper::Decorator
  def self.collection_decorator_class
    PaginatingDecorator
  end
end

class PaginatingDecorator < Draper::CollectionDecorator
  # support for will_paginate
  delegate :current_page, :total_entries, :total_pages, :per_page, :offset

  # FIXME: https://github.com/drapergem/draper/issues/864
  #        Bug in Draper doesn't preserve context when calling query methods like `order`
  #        So, we tack on context manually after calling the original implementation
  #        Remove this method when the above is merged and the gem is updated
  def order(*args)
    collection = super
    collection.context = self.context
    collection
  end

  def paginate(*args)
    object.paginate(*args).decorate(context: self.context)
  end
end
