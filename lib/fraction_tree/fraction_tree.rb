# @author Jose Hales-Garcia
#
class FractionTree
  DEFAULT_TREE_DEPTH = 20

  private_class_method :new

  class << self
    # @return the left-most node of the range of the tree
    # @example
    #   FractionTree.left_node => 0/1
    # @note defaults to Stern-Brocot left-most range, 0
    #
    def left_node
      @left_node || 0/1r
    end

    # @return the right-most node of the range of the tree
    # @example
    #   FractionTree.right_node => Infinity
    # @note defaults to Stern-Brocot right-most range, Infinity
    #
    def right_node
      @right_node || Float::INFINITY
    end

    # Set the left-most node of the range of the tree
    # @example
    #   FractionTree.left_node = 1/1r
    #
    def left_node=(rhs)
      @left_node = rhs
    end

    # Set the right-most node of the range of the tree
    # @example
    #   FractionTree.right_node = 2/1r
    #
    def right_node=(rhs)
      @right_node = rhs
    end

    # @return the range of the tree
    # @example
    #   FractionTree.range => (0/1..Infinity)
    # @note defaults to Stern-Brocot range, (0..Infinity)
    #
    def range
      (left_node..right_node)
    end

    # Set the range of the tree
    # @example
    #   FractionTree.range = :farey
    #   => (0/1..1/1)
    # @note Accepts keywords:
    #   :farey, :keyboard, :scale_step, :log2 => (0/1..1/1)
    #   :stern_brocot, :scale => (0/1..1/0)
    #   :octave_reduced => (1/1..2/1)
    #
    def range=(rhs)
      case rhs
      when :farey, :keyboard, :scale_step, :log2
        @left_node, @right_node = 0/1r, 1/1r
      when :stern_brocot, :scale
        @left_node, @right_node = 0/1r, Float::INFINITY
      when :octave_reduced
        @left_node, @right_node = 1/1r, 2/1r
      else
        @left_node = @right_node = nil
      end
    end

    # The cache of nodes used for faster lookup
    # @note Intended for internal use.
    def nodes
      @@nodes ||= {}
    end

    # Reset the cache of nodes
    # @example
    #   FractionTree.reset_nodes => {}
    #
    def reset_nodes
      @@nodes = {}
    end

    # @return [FractionTree::Node] the node in the tree representing the given number
    # @example
    #   FractionTree.node(3/2r) => (3/2)
    #
    def node(number)
      validate(number)
      nodes[number] ||= Node.new(number)
    end

    # @return [FractionTree::Node] the node decoded from the given string
    # @example
    #   FractionTree.decode("RLL") => (4/3)
    #
    def decode(str)
      wrk_node = Node.decode(str)
      nodes[wrk_node.number] ||= wrk_node
    end

    # @return [FractionTree::Node] the mediant sum of the given numbers
    # @example
    #   FractionTree.mediant_sum(3/2r, 4/3r) => (7/5)
    #
    def mediant_sum(n1, n2)
      Node.new(n1) + Node.new(n2)
    end

    # @return [Boolean] whether two numbers are neighbors
    # @example
    #   FractionTree.neighbors?(3/2r, 4/3r) => true
    #   FractionTree.neighbors?(3/2r, 7/4r) => false
    #   FractionTree.neighbors?(2/1r, Float::INFINITY) => true
    # @param number1 of comparison
    # @param number2 of comparison
    # @note Neighbor definition: abs(a * d - b * c) = 1, for a/b, c/d
    # @note Float::INFINITY => 1/0
    #
    def neighbors?(number1, number2)
      (a, b) = number1.infinite? ? [1, 0] : [number1.numerator, number1.denominator]
      (c, d) = number2.infinite? ? [1, 0] : [number2.numerator, number2.denominator]
      (a * d - b * c).abs == 1
    end

    # @return [Array] a multi-dimensional array of fraction tree nodes
    # @example
    #   FractionTree.tree(depth: 4)
    #   => [[(0/1), (1/0)],
    #       [(1/1)],
    #       [(1/2), (2/1)],
    #       [(1/3), (2/3), (3/2), (3/1)]]
    #
    # @param depth [Integer] the depth of the tree
    # @param left_node [FractionTree::Node] the left starting node
    # @param right_node [FractionTree::Node] the right starting node
    #
    def tree(depth: 10, left_node: default_left_node, right_node: default_right_node)
      Array.new(depth, 0).tap do |sbt|
        row = 0
        sbt[row] = [left_node, right_node]
        i = 2
        while i <= depth do
          figure_from = sbt[0..row].flatten.sort
          new_frow = Array.new(2**(i-2), 0)
          idx = 0
          figure_from.each_cons(2) do |left, right|
            new_frow[idx] = left + right
            idx += 1
          end
          row += 1
          sbt[row] = new_frow
          i += 1
        end
      end
    end

    # @return [FractionTree::Node] the mediant child of the given numbers
    # @example
    #   FractionTree.child_of(1/1r, 4/3r) => (5/4)
    #   FractionTree.child_of(7/4r, 4/3r) => nil
    #
    # @param number1 [Rational] one of two parents
    # @param number2 [Rational] two of two parents
    # @note return nil if bc - ad |= 1, for a/b, c/d
    #
    def child_of(number1, number2)
      return nil unless neighbors?(number1, number2)
      # node(number1.numerator, number1.denominator) + node(number2.numerator, number2.denominator)
      node(number1) + node(number2)
    end

    # @return [Array] of fraction tree nodes descended from parent1 and parent2
    #   Return empty array if bc - ad |= 1, for a/b, c/d
    # @example
    #   FractionTree.descendants_of(1/1r, 4/3r)
    #   => [(1/1), (7/6), (6/5), (11/9), (5/4), (14/11), (9/7), (13/10), (4/3)]
    #
    # @param parent1 [Rational] one of two parents
    # @param parent2 [Rational] two of two parents
    # @param depth [Integer] the depth to collect
    #
    def descendants_of(parent1, parent2, depth: 5)
      return [] unless neighbors?(parent1, parent2)
      sequence(depth:, left_node: Node.new(parent1), right_node: Node.new(parent2))
    end

    # @return [Array] a sequence of fraction tree nodes
    # @example
    #   FractionTree.new.sequence(3)
    #     => [(0/1), (1/3), (1/2), (2/3), (1/1), (3/2), (2/1), (3/1), (1/0)]
    #
    # @param depth [Integer] the number of iterations of the algorithm to run. The number of nodes returned will be greater
    # @param segment [Array] a tuple array of [FractionTree::Node] defining the segment of the tree to collect nodes.
    #
    def sequence(depth: 5, left_node: default_left_node, right_node: default_right_node)
      [left_node]+_sequence(depth:, left_node:, right_node:)+[right_node]
    end

    # @return [Array] of numerators of the fraction tree nodes. Aka the Stern-Brocot sequence.
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
    def validate(num)
      raise(ArgumentError, "#{num} not in range of #{range}", caller[0]) unless range.include?(num)
    end

    def default_left_node
      node(left_node)
    end

    def default_right_node
      node(right_node)
    end

    def _node(num, den=nil)
      if num.kind_of?(Float)
        num = num.to_d
      end
      if num.infinite?
        num, den = 1, 0
      end
      if den.nil?
        den = num.denominator
        num = num.numerator
      end
      Node.new(num, den)
    end

    def _sequence(depth: 5, left_node:, right_node:)
      return [] if depth == 0

      mediant = left_node + right_node

      # Generate left segment, mediant, then right segment
      _sequence(depth: depth - 1, left_node:, right_node: mediant) + [mediant] + _sequence(depth: depth - 1, left_node: mediant, right_node:)
    end
  end
end
