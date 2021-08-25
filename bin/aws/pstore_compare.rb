#!/usr/bin/env ruby
# encoding: UTF-8
# Usage: bin/aws/pstore_compare --file=config/credentials.yml
require 'yaml'
require 'optparse'
require 'byebug'
require 'hashie'
require 'set'
require 'terminal-table'
require 'csv'

unless Gem.loaded_specs.has_key?('terminal-table')
  puts "Missing Terminal table"
  puts "run: gem install terminal-table"
  exit
  # ActiveRecord was activated
end

opts = {}

parser = OptionParser.new do |options|
  options.on '-f', '--file FILE', 'Credentials file to include in comparison' do |arg|
    opts[:file] = arg
  end
  options.on '-p', '--prefixes PREFIX', 'Regex for key prefixes to use (eg, "recognize/patagonia,recognize/staging")' do |arg|
    opts[:prefixes] = arg
  end
  options.on '-o', '--output OUTPUT', 'Output format to use (eg TABLE|CSV)' do |arg|
    opts[:output] = arg
  end

end

parser.parse! ARGV
file = opts[:file]
prefixes = opts[:prefixes].to_s.split(",")
output_format = opts[:output].to_s.downcase == 'csv' ? :csv : :table

def parse_reference_creds(creds)
  reference_creds = {}
  creds.each do |(top_level_key, values)|
    values.each do |k,v|
      if v.kind_of?(Hash)
        sub_creds = parse_reference_creds("#{top_level_key}_#{k}" => v)
        reference_creds.merge!(sub_creds)
      else
        reference_creds[top_level_key+"_"+k] = v
      end
    end
  end
  return reference_creds
end

def parse_pstore_creds(creds)
  print "Parsing pstore creds..."
  pstore_creds = {}
  creds.each do |cred_line|
    full_key, type, value = cred_line.gsub(/\s+/m, ' ').split(" ")
    deployment, environment, key = full_key.gsub(/^\//,'').split("/")
    pstore_creds[key] ||= []
    pstore_creds[key] << {deployment: deployment, environment: environment, value: value, hierarchy_key: "#{deployment}/#{environment}"}
  end
  return pstore_creds
end

def output(format, creds, columns)
  rows, headings = [], []
  headings << ([:key] + columns.to_a)

  creds = creds.sort_by{|k,v| k}

  if format == :csv
    col_width = 10000
  else
    terminal_width = `tput cols`.to_i
    col_width = ((terminal_width-columns.length*4) / (columns.length)) - columns.length*2
  end

  creds.each do |k,cred|
    row = [k.to_s[0..col_width]]
    row += columns.map{|c| cred[c].to_s[0..col_width] }
    rows << row
  end
  
  if format == :csv
    filename = "aws_pstore_#{Time.now.to_s.gsub(' ','').gsub(':','')}.csv"
    CSV.open(filename, 'w') do |csv|
      rows.each do |row|
        csv << row
      end
    end
    puts "Wrote csv file: #{filename}"
  else
    table = Terminal::Table.new :rows => rows, :headings => headings
    puts table
  end
end

def unify(reference_creds, pstore_creds, reference_column_name = :reference)
  unified = {}
  default_columns = reference_creds.length > 0 ? [reference_column_name] : []
  columns = Set.new(default_columns)
  reference_creds.each do |k,v|
    unified[k] ||= Hashie::Mash.new
    unified[k][reference_column_name] = v
  end

  pstore_creds.each do |k,set|
    set.each do |cred_set|
      unified[k] ||= Hashie::Mash.new
      unified[k][cred_set[:hierarchy_key]] = cred_set[:value]
      columns.add(cred_set[:hierarchy_key])
    end
  end
  return [unified, columns]
end

# get and parse reference credentials
if file
  puts "Loading reference creds from: #{file}..."
  reference_creds = YAML.load_file(file)
  parsed_reference_creds = parse_reference_creds(reference_creds)
  puts "Found #{parsed_reference_creds.length}"
else
  parsed_reference_creds = []
end

# get and parse all credentials from pstore
puts "Loading pstore creds...(this may take a moment)..."
pstore_creds = `#{__dir__}/pstore_grep .*`.split("\n")
parsed_pstore_creds = parse_pstore_creds(pstore_creds)
puts "Found #{parsed_pstore_creds.length}"


puts "Creating unified chart..."
unified_creds, columns = unify(parsed_reference_creds, parsed_pstore_creds, file)

if prefixes.length > 0
  columns = columns.select{|c| prefixes.any?{|prefix| c.match(/#{prefix}/)}}
  columns = [file] + columns if file
end
output(output_format, unified_creds, columns)
