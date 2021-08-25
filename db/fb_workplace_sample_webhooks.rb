module FbWorkplaceSampleWebhooks
  # user message webhook
  def user_message
    # {"object"=>"page", "entry"=>[{"id"=>"1714217182220546", "time"=>1506967880977, "messaging"=>[{"sender"=>{"id"=>"321093481697660", "community"=>{"id"=>627102830783995}}, "recipient"=>{"id"=>"1714217182220546"}, "timestamp"=>1506967880902, "message"=>{"mid"=>"mid.$cAAZN5AeuGI9lD45Mxle3kkEkgEG2", "seq"=>1966, "text"=>"hello"}}]}]}
    {
        "object" => "page", "entry" => [{
            "id" => "1714217182220546", "time" => 1506967880977, "messaging" => [{
                "sender" => {
                    "id" => "321093481697660", "community" => {
                        "id" => 627102830783995
                    }
                }, "recipient" => {
                    "id" => "1714217182220546"
                }, "timestamp" => 1506967880902, "message" => {
                    "mid" => "mid.$cAAZN5AeuGI9lD45Mxle3kkEkgEG2", "seq" => 1966, "text" => "hello"
                }
            }]
        }]
    }    
  end

  def mention
    # mention webhook
    # {"entry"=>[{"changes"=>[{"field"=>"mention", "value"=>{"message_tags"=>[{"length"=>9, "offset"=>0, "type"=>"page", "id"=>"1714217182220546", "name"=>"Recognize"}, {"length"=>11, "offset"=>21, "type"=>"user", "id"=>"317974978674016", "name"=>"Alex Grande"}], "sender_name"=>"Peter Philips", "sender_id"=>"321093481697660", "community"=>{"id"=>"627102830783995"}, "post_id"=>"900865370073607_903962259763918", "verb"=>"add", "item"=>"post", "created_time"=>1506971164, "message"=>"Recognize great work Alex Grande"}}], "id"=>"1714217182220546", "time"=>1506971167}], "object"=>"page"}
    {
        "entry" => [{
            "changes" => [{
                "field" => "mention", "value" => {
                    "message_tags" => [{
                        "length" => 9, "offset" => 0, "type" => "page", "id" => "1714217182220546", "name" => "Recognize"
                    }, {
                        "length" => 11, "offset" => 21, "type" => "user", "id" => "317974978674016", "name" => "Alex Grande"
                    }], "sender_name" => "Peter Philips", "sender_id" => "321093481697660", "community" => {
                        "id" => "627102830783995"
                    }, "post_id" => "900865370073607_903962259763918", "verb" => "add", "item" => "post", "created_time" => 1506971164, "message" => "Recognize great work Alex Grande"
                }
            }], "id" => "1714217182220546", "time" => 1506971167
        }], "object" => "page"
    }    
  end

  def postback
    # postback webhook
    # {"object"=>"page", "entry"=>[{"id"=>"1714217182220546", "time"=>1506971619867, "messaging"=>[{"recipient"=>{"id"=>"1714217182220546"}, "timestamp"=>1506971619867, "sender"=>{"id"=>"100013910313357"}, "postback"=>{"payload"=>"{\"action\":\"BadgeChoice\",\"id\":112,\"post_id\":\"900865370073607_903964316430379\"}", "title"=>"Choose"}}]}]}
    {
        "object" => "page", "entry" => [{
            "id" => "1714217182220546", "time" => 1506971619867, "messaging" => [{
                "recipient" => {
                    "id" => "1714217182220546"
                }, "timestamp" => 1506971619867, "sender" => {
                    "id" => "100013910313357"
                }, "postback" => {
                    "payload" => "{\"action\":\"BadgeChoice\",\"id\":112,\"post_id\":\"900865370073607_903964316430379\"}", "title" => "Choose"
                }
            }]
        }]
    }    
  end

  def quick_reply
    {"object"=>"page", "entry"=>[{"id"=>"1714217182220546", "time"=>1507072350821, "messaging"=>[{"sender"=>{"id"=>"317974978674016", "community"=>{"id"=>627102830783995}}, "recipient"=>{"id"=>"1714217182220546"}, "timestamp"=>1507072350783, "message"=>{"quick_reply"=>{"payload"=>"{\"action\":\"BadgeChoice\",\"id\":41,\"post_id\":\"180340515846894_181189335762012\"}"}, "mid"=>"mid.$cAAZN5AONdl5lFchiP1e5IMZexn0F", "seq"=>560, "text"=>"Detailed"}}]}]}
  end

  def params_passed_with_linking_account 
    {"fb_workplace_post_id"=>"900865370073607_915943665232444", "fb_workplace_class"=>"fb_workplace/webhook/page/mention", "fb_workplace_action"=>"show_carousel", "fb_workplace_sender_id"=>"321093481697660", "fb_workplace_community_id"=>"627102830783995"}
  end
end