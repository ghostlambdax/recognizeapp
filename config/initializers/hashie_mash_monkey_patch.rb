
# Hashie compatibility layer for forbidden attributes protection (strong params)
# Derived from hashie-forbidden_attributes mini-gem
# https://github.com/Maxim-Filimonov/hashie-forbidden_attributes/blob/master/lib/hashie-forbidden_attributes/hashie/mash.rb

# Relevant Ticket - https://github.com/intridea/hashie/issues/89
# At the time of writing, this is only needed for the Survey model, which serializes :data as Hashie::Mash

require 'hashie/mash'

module HashieMashDontRespondToPermitted
  def respond_to_missing?(method_name, *args)
    return false if method_name == :permitted?
    super
  end

  def method_missing(method_name, *args)
    fail ArgumentError if method_name == :permitted?
    super
  end
end

Hashie::Mash.prepend(HashieMashDontRespondToPermitted)
