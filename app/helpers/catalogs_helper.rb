module CatalogsHelper
  def formatted_currency_to_points_ratio(catalog)
    '%.2f' % (1 / catalog.points_to_currency_ratio)
  end
end
