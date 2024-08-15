require_relative "extensions"

# @author Jose Hales-Garcia
#
class FractionTree
  class Node
    include Comparable

    attr_reader :numerator, :denominator, :weight

    def initialize(n,d)
      @numerator = n
      @denominator = d
      @weight = (d == 0 ? Float::INFINITY : Rational(@numerator, @denominator))
    end

    alias :to_r :weight

    def inspect
      "(#{numerator}/#{denominator})"
    end
    alias :to_s :inspect

    def <=>(rhs)
      self.weight <=> rhs.weight
    end

    def ==(rhs)
      self.weight == rhs.weight
    end

    # Needed for intersection operations to work.
    # https://blog.mnishiguchi.com/ruby-intersection-of-object-arrays
    # https://shortrecipes.blogspot.com/2006/10/ruby-intersection-of-two-arrays-of.html
    # Also, allows using with Set, which uses Hash as storage and equality of its elements is determined according to Object#eql? and Object#hash.
    #
    def eql?(rhs)
       rhs.instance_of?(self.class) && weight == rhs.weight
    end

    def hash
       p, q = 17, 37
       p = q * @id.hash
       p = q * @name.hash
    end

    def +(rhs)
      self.class.new(self.numerator+rhs.numerator, self.denominator+rhs.denominator)
    end
  end
end
