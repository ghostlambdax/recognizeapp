# This class is a quick hack to handle the fact that companies
# are stuffed too full with serialized attributes that are making
# DelayedJob barf.
# 
# ex. SafeDelayer.delay(queue: 'caching').run(Company, 1, :prime_caches)
# ex. SafeDelayer.delay(queue: 'caching').run(User, 1, :prime_caches)
class SafeDelayer
  def self.run(klass, id, method_name, *args)
    obj = klass.find(id)
    if(obj.method(method_name).arity != 0)
      obj.send(method_name, *args)
    else
      obj.send(method_name)
    end
  end
end
