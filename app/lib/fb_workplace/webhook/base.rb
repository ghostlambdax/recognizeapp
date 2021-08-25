# {"entry"=>[
#   {"changes"=>[{"field"=>"mention", "value"=>{"message_tags"=>[
#     {"length"=>11, "offset"=>12, "type"=>"user", "id"=>"100013845489500", "name"=>"Alex Grande"}, 
#     {"length"=>13, "offset"=>24, "type"=>"page", "id"=>"1999243503640230", "name"=>"RecognizeBot2"}], 
#     "sender_name"=>"Peter Philips", 
#     "sender_id"=>"100013910313357", 
#     "community"=>{"id"=>community_id}, 
#     "post_id"=>"1575495049137892_1588391981181532", 
#     "verb"=>"add", 
#     "item"=>"post", 
#     "created_time"=>1505949097, 
#     "message"=>"gräöåt work Alex Grande RecognizeBot2"}}], 
# "id"=>"1999243503640230", 
# "time"=>1505949098}], 
# "object"=>"page", 
# "workplace"=>{"entry"=>[{"changes"=>[{"field"=>"mention", "value"=>{"message_tags"=>[{"length"=>11, "offset"=>12, "type"=>"user", "id"=>"100013845489500", "name"=>"Alex Grande"}, {"length"=>13, "offset"=>24, "type"=>"page", "id"=>"1999243503640230", "name"=>"RecognizeBot2"}], "sender_name"=>"Peter Philips", "sender_id"=>"100013910313357", "community"=>{"id"=>"627102830783995"}, "post_id"=>"1575495049137892_1588391981181532", "verb"=>"add", "item"=>"post", "created_time"=>1505949097, "message"=>"gräöåt work Alex Grande RecognizeBot2"}}], "id"=>"1999243503640230", "time"=>1505949098}], "object"=>"page"}}
class FbWorkplace::Webhook::Base
  attr_reader :payload, :request_uuid

  def initialize(payload, request_uuid: )
    @payload = Hashie::Mash.new(payload)
    @request_uuid = request_uuid
  end

  def entries
    payload.entry.map{|e| FbWorkplace::Webhook::Entry.new(e, self) }
  end

  def inspect
    self.payload.inspect
  end

  def log(msg)
    FbWorkplace::Logger.log(msg, uuid: request_uuid)
  end
end
