module Arke::Helpers
  module Precision
    def apply_precision(value, precision, min_value = nil)
      value = value.round(12).floor(precision)
      if !min_value.nil? and value < min_value
        value = min_value
      end
      value
    end
  end
end
