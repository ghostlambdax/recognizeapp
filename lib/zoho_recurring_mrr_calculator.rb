# View Recurring Invoice Details Report and Search for 1/1/1990 (far past) to 12/31/2050 (far future)
# make sure date range is Jan 1 to 12/31 as well
# USAGE: bundle exec rails r lib/zoho_recurring_mrr_calculator.rb --file=tmp/recurring_invoice_details.csv
require 'csv'
require 'optparse'
require 'byebug'
require 'active_support/core_ext/enumerable'
require 'money'

opts = {}

parser = OptionParser.new do |options|
  options.on '-f', '--file FILE', 'CSV file with data to bulk recognize' do |arg|
    opts[:file] = arg
  end
end


parser.parse! ARGV
file = opts[:file]
puts "Opening file: #{file}"
csv = CSV.read(file, encoding: "ISO8859-1")

SCHEMA1 = {
  recurring_invoice_id: 0,
  customer_name: 2,
  interval: 10,
  frequency: 11,
  currency: 13,
  amount: 15
}

SCHEMA=SCHEMA1
csv.shift # remove headers

class Customer
  attr_reader :row, :schema

  def initialize(row, schema)
    @row, @schema = row, schema
    # @customer_name, @frequency, @amount = customer_name, frequency, amount
  end

  def mrr
    amount_in_cents = amount.to_f*100
    money = Money.new(amount_in_cents, currency)
    usd_amount = begin
      money.exchange_to('USD')
    rescue SocketError
      amount.to_f
    end
    puts "[#{customer_name}]: Amount(#{amount} #{currency}) exchange to: #{usd_amount} (USD)"

    # if currency != "USD"
    #   puts "Unsupported currency: #{row}"
    #   return 0
    # end
    
    if monthly?
      usd_amount.to_f / frequency.to_i

    elsif annual?
      (usd_amount.to_f / frequency.to_i) / 12.0

    else
      raise "Unsupported: #{row}"
    end
  end

  def arr
    mrr * 12
  end

  def method_missing(m, *args, &block)
    if SCHEMA.keys.include?(m.to_sym)
      row[SCHEMA[m]].strip
    else
      super
    end
    # frequency = row[SCHEMA[:frequency]].strip
    # amount = row[SCHEMA[:amount]].strip
    # customer_name = row[SCHEMA[:customer_name]].strip

  end

  private
  def monthly?
    interval.to_s.downcase == 'months'
  end

  def annual?
    interval.to_s.downcase == 'years'
  end
end

customers = []
csv.each do |row|
  customer = Customer.new(row, SCHEMA)
  customers << customer
end

total_mrr = customers.sum(&:mrr)

puts "Total Zoho MRR: #{total_mrr} across #{customers.length} customers"
