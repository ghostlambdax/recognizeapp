# Actors are generic entities who perform actions
# and have a standard interface for display (ie #label)
# This concern is more dealing with classes that store a "signature"
# which is used to reconstitute who the actor is (ie class and id)
module ActorConcern
  def self.actor_from_signature(signature)
    klass, id = signature.split("|")
    klass = klass.constantize
    klass.respond_to?(:find_by_id) ? klass.find_by_id(id) : klass.new(id)
  end

  def actor_signature
    "#{self.class}|#{self.actor_signature_id}"
  end

  # this can be overridden if necessary
  # to customize behavior
  def actor_signature_id
    self.id
  end
end