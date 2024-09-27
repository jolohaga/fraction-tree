# @author Jose Hales-Garcia
#
class FractionTree
  class Node
    extend Forwardable
    include Comparable

    def_delegators :@number, :zero?, :infinite?

    attr_reader :numerator, :denominator, :number

    IDENTITY_MATRIX = Matrix.identity(2)
    LEFT_MATRIX = Matrix[[1,1],[0,1]]
    RIGHT_MATRIX = Matrix[[1,0],[1,1]]

    def initialize(num)
      (@numerator, @denominator) = fraction_pair(num)
      @number = num
    end

    alias :to_r :number

    class << self
      # @return [FractionTree::Node] the fraction decoded from the given string
      # @example
      #   FractionTree::Node.decode("RLL") => (4/3)
      #
      def decode(string)
        result = IDENTITY_MATRIX

        string.split("").each do |direction|
          case direction
          when "L", "0", "l"
            result = result * LEFT_MATRIX
          when "R", "1", "r"
            result = result * RIGHT_MATRIX
          end
        end
        FractionTree.node(Rational(result.row(1).sum, result.row(0).sum))
      end

      # @return [String] the Stern-Brocot encoding of number
      # @example
      #   FractionTree::Node.encode(4/3r) => "RLL"
      # @param limit of codes to generate
      #
      def encode(number, limit: Float::INFINITY)
        return nil if (number.infinite? || number.zero?)

        m = number.numerator
        n = number.denominator

        return "I" if m == n

        "".tap do |string|
          while m != n && string.length < limit
            if m < n
              string << "L"
              n = n - m
            else
              string << "R"
              m = m - n
            end
          end
        end
      end

      # @return [Array] pair of numbers less and greater than the provided number by provided difference
      # @example
      #   FractionTree::Node.plus_minus(3, 2) => [1, 5]
      # @param
      #   num the base
      #   diff the number subtracted and added to base
      #
      def plus_minus(num, diff)
        [num - diff, num + diff]
      end

      # @return [Integer] the decimal power of the provided number
      # @example
      #   FractionTree::Node.decimal_power(1000) => 3
      # @param
      #   logarithmand the number from which the log base 10 is obtained
      #
      def decimal_power(logarithmand)
        Math.log10(logarithmand.abs).floor
      end
    end

    # @return [Array] set of fraction tree nodes leading to the given number
    # @example
    #    FractionTree.node(7/4r).path
    #    => [(0/1), (1/0), (1/1), (2/1), (3/2), (5/3), (7/4)]
    # @limit of nodes to generate
    #
    def path(limit: Float::INFINITY)
      return nil if infinite? || zero?

      ln = tree.node(FractionTree.left_node)
      rn = tree.node(FractionTree.right_node)
      mn = ln + rn
      return [ln, rn, mn] if mn == tree.node(number)

      result = IDENTITY_MATRIX
      m = numerator
      n = denominator
      [].tap do |p|
        p << ln << rn << mn
        while m != n && p.length < limit
          if m < n
            result = result * LEFT_MATRIX
            n = n - m
          else
            result = result * RIGHT_MATRIX
            m = m - n
          end
          p << tree.node(Rational(result.row(1).sum,result.row(0).sum))
        end
      end
    end

    # @return [Array] a pair of fraction tree nodes leading to the given number.
    # @example
    #   FractionTree.node(15/13r).parents => [(8/7), (7/6)]
    #   FractionTree.node(Math::PI).parents => [(1181999955934188/376242271442657), (1959592697655605/623757728557343)]
    #
    def parents
      tmp = path
      [tmp[-2], tmp[-2..-1].inject(&:-)].sort
    end

    # @return [Array] of [FractionTree::Node], sequence of Farey neighbors to self. A Farey neighbor is a number c/d, who's relationship to a/b is such that ad − bc = 1, when c/d < a/b and bc − ad = 1 when c/d > a/b.
    # @example
    #   FractionTree.node(3/2r).neighbors(10)
    #   => [(1/1), (2/1), (4/3), (5/3), (7/5), (8/5), (10/7), (11/7), (13/9), (14/9)]
    # @param r range of harmonic series to search
    #
    def neighbors(r = 10**(self.class.decimal_power(number.numerator)+2))
      ratio = number.to_r
      denominator = ratio.denominator

      [].tap do |collection|
        (1..r-1).each do |i|
          lower, upper = self.class.plus_minus(ratio, Rational(1,i*denominator))
          collection << tree.node(lower) if tree.neighbors?(ratio, lower)
          collection << tree.node(upper) if tree.neighbors?(ratio, upper)
        end
      end
    end

    # @return [Array] the ancestors shared by self and the given number
    # @example
    #   FractionTree.node(4/3r).common_ancestors_with(7/4r)
    #   => [(0/1), (1/0), (1/1), (2/1), (3/2)]
    #
    # @param num [Numeric] other number sharing descendants with self
    #
    def common_ancestors_with(num)
      path & tree.node(num).path
    end

    # @return [Array] of fraction tree nodes, descending from parents of number
    # @example
    #   FractionTree.node(5/4r).descendancy_from(depth: 3)
    #   => [(1/1), (7/6), (6/5), (11/9), (5/4), (14/11), (9/7), (13/10), (4/3)]
    #
    # @param depth [Integer] how many nodes to collect
    #
    def descendancy_from(depth: 5)
      (parent1, parent2) = parents
      tree.descendants_of(parent1.number, parent2.number, depth:)
    end

    # @return [FractionTree::Node] child of self and given number
    # @example
    #   FractionTree.node(5/4r).child_with(4/3r)
    #   => (9/7)
    # @note return nil if bc - ad |= 1, for a/b, c/d
    #
    def child_with(num)
      tree.child_of(number, num)
    end

    # @return [String] encoding of self
    # @example
    #   FractionTree.node(Math.log2(5/4r)).encoding(limit: 30) => "LLLRRRRRRRRRLLRRLLLLRRRRRRLLRL"
    # @param limit of codes to generate
    #
    def encoding(limit: Float::INFINITY)
      self.class.encode(number, limit:)
    end

    # @return [FractionTree::Node] sum of self and another node
    # @example
    #   FractionTree.node(5/4r) + FractionTree.node(3/2r)
    #   => (4/3)
    #
    def +(rhs)
      tree.node(Rational(self.numerator+rhs.numerator, self.denominator+rhs.denominator))
    end

    # @return [FractionTree::Node] difference of self and another node
    # @example
    #   FractionTree.node(5/4r) - FractionTree.node(3/2r)
    #   => (1/1)
    #
    def -(rhs)
      tree.node(Rational((self.numerator-rhs.numerator).abs, (self.denominator-rhs.denominator).abs))
    end

    def inspect
      "(#{numerator}/#{denominator})"
    end
    alias :to_s :inspect

    def <=>(rhs)
      self.number <=> rhs.number
    end

    def ==(rhs)
      self.number == rhs.number
    end

    # Needed for intersection operations to work.
    # https://blog.mnishiguchi.com/ruby-intersection-of-object-arrays
    # https://shortrecipes.blogspot.com/2006/10/ruby-intersection-of-two-arrays-of.html
    # Also, allows using with Set, which uses Hash as storage and equality of its elements is determined according to Object#eql? and Object#hash.
    #
    def eql?(rhs)
       rhs.instance_of?(self.class) && number == rhs.number
    end

    def hash
       p, q = 17, 37
       p = q * @id.hash
       p = q * @name.hash
    end

    private
    def tree
      FractionTree #self.class.tree
    end

    def fraction_pair(number)
      if number.infinite?
        [1, 0]
      else
        [number.numerator, number.denominator]
      end
    end
  end
end
