# frozen_string_literal: true

class Array
  # File activesupport/lib/active_support/core_ext/array/grouping.rb, line 22
  def in_groups_of(number, fill_with=nil, &block)
    if number.to_i <= 0
      raise ArgumentError,
            "Group size must be a positive integer, was #{number.inspect}"
    end

    if fill_with == false
      collection = self
    else
      # size % number gives how many extra we have;
      # subtracting from number gives how many to add;
      # modulo number ensures we don't add group of just fill.
      padding = (number - size % number) % number
      collection = dup.concat(Array.new(padding, fill_with))
    end

    if block_given?
      collection.each_slice(number, &block)
    else
      collection.each_slice(number).to_a
    end
  end
end
