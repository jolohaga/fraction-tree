require "bigdecimal/util"
require "continued_fractions"

# @author Jose Hales-Garcia
#
class FractionTree
  DEFAULT_TREE_DEPTH = 20

  class << self
    # @return [Array] the boundary nodes of the tree
    # @example
    #   FractionTree.base_segment => [(0/1), (1/0)]
    #
    def base_segment
      [Node.new(0,1), Node.new(1,0)]
    end

    # @return [Array] a multi-dimensional array with the elements of fraction tree, organized by level/row
    # @example
    #   FractionTree.tree(4)
    #   => [[(0/1), (1/0)],
    #       [(1/1)],
    #       [(1/2), (2/1)],
    #       [(1/3), (2/3), (3/2), (3/1)]]
    #
    # @param number [Integer] the depth of the tree
    #
    def tree(depth=DEFAULT_TREE_DEPTH)
      Array.new(depth, 0).tap do |sbt|
        row = 0
        sbt[row] = base_segment
        i = 2
        while i <= depth do
          figure_from = sbt[0..row].flatten.sort
          new_frow = Array.new(2**(i-2), 0)
          idx = 0
          figure_from.each_cons(2) do |left,right|
            new_frow[idx] = Node.new(left.numerator+right.numerator, left.denominator+right.denominator)
            idx += 1
          end
          row += 1
          sbt[row] = new_frow
          i += 1
        end
      end
    end

    # @return [Array] a sequence of fraction tree nodes
    # @example
    #   FractionTree.sequence(3)
    #     => [(0/1), (1/3), (1/2), (2/3), (1/1), (3/2), (2/1), (3/1), (1/0)]
    #
    # @param depth [Integer] the number of iterations of the algorithm to run. The number of nodes returned will be greater
    # @param segment [Array] a tuple array of [FractionTree::Node] defining the segment of the tree to collect nodes.
    #
    def sequence(depth=5, segment: base_segment)
      [segment.first]+_sequence(depth, segment:)+[segment.last]
    end

    # @return [Array] set of fraction nodes leading to the given number
    # @example 
    #    FractionTree.path_to(7/4r) => [(1/1), (2/1), (3/2), (5/3), (7/4)]
    #
    # @param number [Rational] the target the fraction path leads to
    # @param find_parents [Boolean] list all ancestors or only immediate parents
    # @param segment [Array] a tuple of [FractionTree::Node], defining the segment's starting left and right boundaries
    #
    def path_to(number, find_parents: false, segment: base_segment)
      validate(number)
      return Node.new(number.numerator, number.denominator) if number.zero?
      number = number.kind_of?(Float) ? number.to_d : number

      q = Node.new(number.numerator, number.denominator)
      l = segment.first
      h = segment.last
      not_found = true
      parents = []
      results = segment
      while not_found
        m = (l + h)
        if m < q
          l = m
        elsif m > q
          h = m
        else
          parents << l << h
          not_found = false
        end
        results << m
      end
      find_parents == false ? results : parents
    end

    # @return [Array] a pair of fraction tree nodes leading to the given number.
    #   For irrational numbers, the parent nodes are one of an infinite series, whose nearness is determined by the limits of the system
    # @example
    #   FractionTree.parents_of(15/13r) => [(8/7), (7/6)]
    #   FractionTree.parents_of(Math::PI) => [(447288330638589/142376297616907), (436991388364966/139098679093749)]
    #
    # @param number [Rational] the child number whose parents are being sought
    #
    def parents_of(number)
      path_to(number, find_parents: true)
    end

    # @return [Array] the ancestors shared by the given descendants
    # @example
    #   FractionTree.common_ancestors_between(4/3r, 7/4r)
    #   => [(1/1), (2/1), (3/2)]
    #
    # @param number1 [Rational] one of two descendants
    # @param number2 [Rational] two of two descendants
    #
    def common_ancestors_between(number1, number2)
      path_to(number1) & path_to(number2)
    end

    # @return [Array] the descendants of number starting at its parents
    # @example
    #   FractionTree.descendancy_from(5/4r, 3)
    #   => [(1/1), (7/6), (6/5), (11/9), (5/4), (14/11), (9/7), (13/10), (4/3)]
    #
    # @param number [Rational] around which descendancy is focused
    # @param depth [Integer] how many nodes to collect
    #
    def descendancy_from(number, depth=5)
      parent1, parent2 = parents_of(number)
      descendants_of(parent1, parent2, depth)
    end

    # @return [FractionTree::Node] the mediant child of the given numbers
    #   Return nil if bc - ad |= 1, for a/b, c/d
    # @example
    #   FractionTree.child_of(1/1r, 4/3r) => (5/4)
    #   FractionTree.child_of(7/4r, 4/3r) => nil
    #
    # @param number1 [Rational] one of two parents
    # @param number2 [Rational] two of two parents
    # @param strict_neighbors [Boolean] whether to apply the strict Farey tree neighbor requirement
    #
    def child_of(number1, number2, strict_neighbors: true)
      return nil unless farey_neighbors?(number1, number2) || !strict_neighbors
      Node.new(number1.numerator, number1.denominator) + Node.new(number2.numerator, number2.denominator)
    end

    # @return [Array] of nodes descended from parent1 and parent2
    #   Return empty array if bc - ad |= 1, for a/b, c/d
    # @example
    #   FractionTree.descendants_of(1/1r, 4/3r, 3)
    #   => [(1/1), (7/6), (6/5), (11/9), (5/4), (14/11), (9/7), (13/10), (4/3)]
    #
    # @param parent1 [Rational] one of two parents
    # @param parent2 [Rational] two of two parents
    # @param depth [Integer] the depth to collect
    # @param strict_neighbors [Boolean] whether to apply the strict Farey tree neighbor requirement
    #
    def descendants_of(parent1, parent2, depth=5, strict_neighbors: true)
      return [] unless farey_neighbors?(parent1, parent2) || !strict_neighbors
      segment = [Node.new(parent1.numerator, parent1.denominator), Node.new(parent2.numerator, parent2.denominator)]
      sequence(depth, segment: segment)
    end

    # @return [Array] of FractionTree::Nodes leading quotient-wise to number
    # @example
    #   FractionTree.quotient_walk(15/13r)
    #   => [(1/1), (2/1), (3/2), (4/3), (5/4), (6/5), (7/6), (8/7), (15/13)]
    #
    # @param number [Numeric] to walk toward
    # @param limit [Integer] the depth of the walk. Useful for irrational numbers
    # @param segment [Array] the tuple of [FractionTree::Node] defining the segment of the tree
    #
    def quotient_walk(number, limit: 10, segment: computed_base_segment(number))
      iterating_quotients = ContinuedFraction.new(number, limit).quotients.drop(1)
      comparing_node = Node.new(number.numerator, number.denominator)

      segment.tap do |arr|
        held_node = arr[-2]
        moving_node = arr[-1]

        iterating_quotients.each do |q|
          (1..q).each do |i|
            arr << held_node + moving_node
            # We don't want to walk past the number when it's a rational number and we've reached it
            break if arr.include?(comparing_node)
            moving_node = arr[-1]
          end
          held_node = arr[-2]
        end
      end
    end

    # @return [Array] of numerators of the fraction tree nodes. Also known as the Stern-Brocot sequence.
    # @example
    #   FractionTree.numeric_sequence.take(12)
    #   => [1, 1, 2, 1, 3, 2, 3, 1, 4, 3, 5, 2]
    #
    def numeric_sequence
      return enum_for :numeric_sequence unless block_given?
      a=[1,1]

      0.step do |i|
        yield a[i]
        a << a[i]+a[i+1] << a[i+1]
      end
    end

    # @return [Array] of Farey neighbors to the given number. A Farey neighbor is a number b/c, who's relationship to a/b is such that ad − bc = 1, when c/d < a/b and bc − ad = 1 when c/d > a/b.
    # @example
    #   FractionTree.farey_neighbors(3/2r, 10)
    #   => [(1/1), (2/1), (4/3), (5/3), (7/5), (8/5), (10/7), (11/7), (13/9), (14/9)]
    # @param number with neighbors
    # @param range of harmonic series to search
    #
    def farey_neighbors(number, range = 10**(decimal_power(number.numerator)+2))
      ratio = number.to_r
      denominator = ratio.denominator

      [].tap do |collection|
        (1..range-1).each do |i|
          lower, upper = plus_minus(ratio, Rational(1,i*denominator))
          collection << lower if farey_neighbors?(ratio, lower)
          collection << upper if farey_neighbors?(ratio, upper)
        end
      end
    end

    # @return [Boolean] whether two numbers are Farey neighbors
    # @example
    #   FractionTree.farey_neighbors?(3/2r, 4/3r) => true
    #   FractionTree.farey_neighbors?(3/2r, 7/4r) => false
    # @param num1 of comparison
    # @param num2 of comparison
    #
    def farey_neighbors?(num1, num2)
      (num1.numerator * num2.denominator - num1.denominator * num2.numerator).abs == 1
    end

    private
    def validate(number)
      raise(ArgumentError, "#{number} not in range of #{base_segment}", caller[0]) unless (base_segment.first.weight..base_segment.last.weight).include?(number)
    end

    def computed_base_segment(number)
      floor = number.floor
      [Node.new(floor,1), Node.new(floor+1,1)]
    end

    def _sequence(depth = 5, segment:)
      return [] if depth == 0

      mediant = segment.first + segment.last

      # Generate left segment, mediant, then right segment
      _sequence(depth - 1, segment: [segment.first, mediant]) + [mediant] + _sequence(depth - 1, segment: [mediant, segment.last])
    end

    def plus_minus(number, diff)
      [number - diff, number + diff]
    end

    def decimal_power(number)
      Math.log10(number.abs).floor
    end
  end

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

class SternBrocotTree < FractionTree; end
class ScaleTree < FractionTree; end

class OctaveReducedTree < FractionTree
  def self.base_segment
    [Node.new(1,1), Node.new(2,1)]
  end
end

class FareyTree < FractionTree
  def self.base_segment
    [Node.new(0,1), Node.new(1,1)]
  end
end

class KeyboardTree < FareyTree; end
class ScaleStepTree < FareyTree; end
class Log2Tree < FareyTree; end
