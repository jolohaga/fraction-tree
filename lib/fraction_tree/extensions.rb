class String
  # @return [FractionTree::Node] string Stern-Brocot decoded
  # @example
  #   "1/0".to_node => (1/0)
  #
  def to_node
    if self.include?(".")
      number = self.to_d
      numerator, denominator = number.numerator, number.denominator
    elsif self.include?("/")
      (numerator, denominator) = self.split("/").map(&:to_i)
    else
      number = self.to_r
      numerator, denominator = number.numerator, number.denominator
    end
    number = denominator.zero? ? Float::INFINITY : Rational(numerator, denominator)
    FractionTree::Node.new(number)
  end
end

class Numeric
  # @return [FractionTree::Node] string Stern-Brocot decoded
  # @example
  #   Float::INFINITY.to_node => (1/0)
  #
  def to_node
    FractionTree.node(self)
  end
end
