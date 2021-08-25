def load_anniversary_badges
  congrats_message = ->(period) { "Congratulations on your #{period} of service with $$company_name$$!"}

  # Unique badges
  hash = {
    "00_birthday" => Hashie::Mash.new({
      # if birthday template id changes, update Badge::BIRTHDAY_TEMPLATE_ID
      template_id: "00_birthday",
      name: "Happy Birthday",
      image: "birthday.png",
      message: "Happy Birthday!"
    }),
    "01week" => Hashie::Mash.new({
      template_id: "01week", # need leading zero for this to show up before '1month' badge in listing
      name: "One week of service",
      image: "oneweek.png",
      message: congrats_message['first week']
    })
  }

  # Month of Service badges
  {
    1 => { label: 'one' },
    3 => { label: 'three' },
    6 => { label: 'six' }
  }.each do |i, opts|
    label = opts[:label]
    month_or_months = 'month'.pluralize(i)
    template_id = "#{i}#{month_or_months}"
    hash[template_id] = Hashie::Mash.new({
      template_id: template_id,
      name: "#{label.capitalize} #{month_or_months} of service",
      image: "#{label}month.png",
      message: congrats_message["#{i.ordinalize} month"]
    })
  end

  # Year of Service badges
  (1..60).each do |i|
    index = i.to_s.rjust(2, '0')
    hash["year_#{index}"] = Hashie::Mash.new({
      template_id: "year_#{index}",
      name: "#{i.ordinalize} Year of Service",
      image: "#{index}.png",
      message: congrats_message["#{i.ordinalize} year"]
   })
  end

  hash.transform_values { |v| v[:points] ||= 10 } # set default points

  return hash
end

ANNIVERSARY_BADGES ||= load_anniversary_badges
