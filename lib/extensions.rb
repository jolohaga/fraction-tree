class String
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
    FractionTree::Node.new(numerator, denominator)
  end
end
