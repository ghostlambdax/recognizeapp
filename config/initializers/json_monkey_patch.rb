# Deprecating 2019-08-30
# This seems to have only be put in place for Travis workaround

# if Rails.env.test?
#   module JSON
#     class << self
#       def parse(source, opts = {})
#         opts = ({:max_nesting => 500}).merge(opts)
#         Parser.new(source, opts).parse
#       end
#     end
#   end
# end
