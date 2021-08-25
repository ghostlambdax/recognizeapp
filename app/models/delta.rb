# frozen_string_literal: true

Delta = Struct.new(:previous_value, :final_value) do
  delegate :positive?, :negative?, :zero?, to: :delta

  def delta
    (final_value - previous_value)
  end

  def percent_change
    return 0 if delta == 0 # handles NaN when both are 0
    return 0 if previous_value == 0

    # For the cases when the final == 0,
    # this will return -Infinity and that's ok
    # clients should handle this case specifically.
    denominator = previous_value #delta.positive? ? previous_value : final_value
    (delta / denominator.to_f) * 100 
  end

end
