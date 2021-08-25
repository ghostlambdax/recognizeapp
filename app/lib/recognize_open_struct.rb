# OpenStruct decided at some point
# that to_json would add a root of "table" to it
# Let's get rid of that
require "ostruct"
class RecognizeOpenStruct < OpenStruct
  def as_json(options = nil)
    @table.as_json(option)
  end
end