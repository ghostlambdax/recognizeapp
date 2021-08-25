class BadgeFinder
  attr_accessor :company

  def self.find(company, name)
    new(company).find(name)
  end

  def initialize(company)
    @company = company
  end

  def find(name)
    find_by_encoded_id(name) || find_by_name(name)
  end

  def badges
    company.company_badges
  end

  private
  def find_by_encoded_id(name)

    is_i?(name) ?
      Badge.find(name) :
      Badge.where(id: Recognize::Application.hasher.decode(name)).first
  end

  def find_by_name(name)
    badges.detect do |b|
      b.short_name.match(/#{name}/i)
    end
  end

  def is_i?(number)
    !!(number =~ /\A[-+]?[0-9]+\z/)
  end
end