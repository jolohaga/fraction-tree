require "bigdecimal/util"
require "continued_fractions"
require_relative "node"

# @author Jose Hales-Garcia
#
class FractionTree
  SB_ENDPOINTS = [Node.new(0,1), Node.new(1,0)]
  FAREY_ENDPOINTS = [Node.new(0,1), Node.new(1,1)]
  OR_ENDPOINTS = [Node.new(1,1), Node.new(2,1)]
  KNOWN_ENDPOINTS = { stern_brocot: SB_ENDPOINTS,
                      scale: SB_ENDPOINTS,
                      octave_reduced: OR_ENDPOINTS,
                      farey: FAREY_ENDPOINTS,
                      keyboard: FAREY_ENDPOINTS,
                      scale_step: FAREY_ENDPOINTS,
                      log2: FAREY_ENDPOINTS, }
  DEFAULT_TREE_DEPTH = 20

  attr_reader :endpoints

  # @return [FractionTree] calculator spanning the range provided or defaulted
  #
  # @example
  #   FractionTree.new
  #   FractionTree.new(:farey)
  #   FractionTree.new(:scale)
  #   FractionTree.new(%w{0/1 1/2})
  # @param
  #   range a tree keyword or a string denoting the tree's end-points
  #
  def initialize(tree_key = :stern_brocot, **kwargs) #endpoints = :stern_brocot)
    @endpoints = determine_endpoints(tree_key, kwargs)
  end

  class << self
    # Define class convenience methods to instantiate the known fraction trees.
    # For example, one can instantiate a Farey tree with the bit shorter
    # FractionTree.farey, instead of using FractionTree.new("farey").
    #
    KNOWN_ENDPOINTS.keys.each do |key|
      define_method(key) do
        new(key)
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

    private
    # @return [Array] pair of numbers less and greater than the provided number by provided difference
    # @param
    #   number the base
    #   diff the number subtracted and added to base
    #
    def plus_minus(number, diff)
      [number - diff, number + diff]
    end

    # @return [Integer] the decimal power of the provided number
    # @param
    #   logarithmand the number from which the log base 10 is obtained
    #
    def decimal_power(logarithmand)
      Math.log10(logarithmand.abs).floor
    end
  end

  # @return [Array] set of fraction nodes leading to the given number
  # @example
  #    FractionTree.new.path_to(7/4r) => [(0/1), (1/0), (1/1), (2/1), (3/2), (5/3), (7/4)]
  #
  # @param number [Rational] the target the tree path leads
  # @param find_parents [Boolean] list all ancestors or only immediate parents
  #
  def path_to(number, find_parents: false)
    validate(number)
    return endpoints.first if endpoints.first.weight == number
    return endpoints.last if endpoints.last.weight == number

    number = number.kind_of?(Float) ? number.to_d : number

    q = Node.new(number.numerator, number.denominator)
    l = endpoints.first
    h = endpoints.last
    not_found = true
    parents = []
    results = [l,h]
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
  #   FractionTree.new.parents_of(15/13r) => [(8/7), (7/6)]
  #   FractionTree.new.parents_of(Math::PI) => [(447288330638589/142376297616907), (436991388364966/139098679093749)]
  #
  # @param number [Rational] the child number whose parents are being sought
  #
  def parents_of(number)
    path_to(number, find_parents: true)
  end

  # @return [Array] the ancestors shared by the given descendants
  # @example
  #   FractionTree.new.common_ancestors_between(4/3r, 7/4r)
  #   => [(1/1), (2/1), (3/2)]
  #
  # @param number1 [Rational] one of two descendants
  # @param number2 [Rational] two of two descendants
  #
  def common_ancestors_between(number1, number2)
    path_to(number1) & path_to(number2)
  end

  # @return [Array] a sequence of fraction tree nodes
  # @example
  #   FractionTree.new.sequence(3)
  #     => [(0/1), (1/3), (1/2), (2/3), (1/1), (3/2), (2/1), (3/1), (1/0)]
  #
  # @param depth [Integer] the number of iterations of the algorithm to run. The number of nodes returned will be greater
  # @param segment [Array] a tuple array of [FractionTree::Node] defining the segment of the tree to collect nodes.
  #
  def sequence(depth=5, segment: endpoints.clone)
    [segment.first]+_sequence(depth, segment:)+[segment.last]
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
    return [] unless self.class.farey_neighbors?(parent1, parent2) || !strict_neighbors
    segment = [Node.new(parent1.numerator, parent1.denominator), Node.new(parent2.numerator, parent2.denominator)]
    sequence(depth, segment: segment)
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

  # @return [Array] of FractionTree::Nodes leading quotient-wise to number
  # @example
  #   FractionTree.quotient_walk(15/13r)
  #   => [(1/1), (2/1), (3/2), (4/3), (5/4), (6/5), (7/6), (8/7), (15/13)]
  #
  # @param number [Numeric] to walk toward
  # @param limit [Integer] the depth of the walk. Useful for irrational numbers
  # @param segment [Array] the tuple of [FractionTree::Node] defining the segment of the tree
  #
  def quotient_walk(number, limit: 10)
    iterating_quotients = ContinuedFraction.new(number, limit).quotients.drop(1)
    comparing_node = Node.new(number.numerator, number.denominator)

    endpoints.clone.tap do |arr|
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

  # @return [Array] a multi-dimensional array with the elements of fraction tree, organized by level/row
  # @example
  #   FractionTree.new.tree(4)
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
      sbt[row] = endpoints.clone
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

  private
  def _sequence(depth = 5, segment:)
    return [] if depth == 0

    mediant = segment.first + segment.last

    # Generate left segment, mediant, then right segment
    _sequence(depth - 1, segment: [segment.first, mediant]) + [mediant] + _sequence(depth - 1, segment: [mediant, segment.last])
  end

  def validate(number)
    raise(ArgumentError, "#{number} not in range of #{endpoints}", caller[0]) unless (endpoints.first.weight..endpoints.last.weight).include?(number)
  end

  def determine_endpoints(tree_key, kwargs)
    if kwargs.key?(:node1) && kwargs.key?(:node2)
      [kwargs[:node1].to_s.to_node, kwargs[:node2].to_s.to_node].sort
    elsif kwargs.key?(:nodes)
      [kwargs[:nodes][0].to_s.to_node, kwargs[:nodes][1].to_s.to_node].sort
    else
      tree_key = tree_key || :stern_brocot
      case tree_key
      when String
        KNOWN_ENDPOINTS[tree_key.downcase.to_sym] || SB_ENDPOINTS
      when Symbol
        KNOWN_ENDPOINTS[tree_key] || SB_ENDPOINTS
      else
        raise(ArgumentError, "Endpoints must be a string or symbol. Examples: #{KNOWN_ENDPOINTS.keys.map(&:to_s) + ['%w{0/1 1/0}']}", caller[0])
      end
    end
  end
end
