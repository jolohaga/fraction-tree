require "spec_helper"

RSpec.describe FractionTree do
  describe ".new" do
    context "with only the positional argument" do
      subject { described_class.new(arg) }

      context "with no arg" do
        it "defaults to the Stern-Brocot tree" do
          expect(described_class.new.endpoints).to eq [described_class::Node.new(0,1), described_class::Node.new(1,0)]
        end
      end

      context "with nil value" do
        let(:arg) { nil }

        it "accepts them" do
          expect(subject.endpoints).to eq [described_class::Node.new(0,1), described_class::Node.new(1,0)]
        end
      end

      context "with tree keyword symbols" do
        let(:arg) { :farey }

        it "accepts them" do
          expect(subject.endpoints).to eq [described_class::Node.new(0,1), described_class::Node.new(1,1)]
        end
      end

      context "with tree keyword strings" do
        let(:arg) { "octave_reduced" }

        it "accepts them" do
          expect(subject.endpoints).to eq [described_class::Node.new(1,1), described_class::Node.new(2,1)]
        end
      end

      context "with mixed-case tree keyword strings" do
        let(:arg) { "oCtaVe_ReDuCeD" }

        it "accepts them" do
          expect(subject.endpoints).to eq [described_class::Node.new(1,1), described_class::Node.new(2,1)]
        end
      end
    end

    context "with positional and keyword arguments" do

    end

    context "with only keyword arguments" do
      context "recognized keywords" do
        describe "nodes" do
          let(:nodes) { %w{0/1 1/2} }

          it "recognizes it" do
            expect(described_class.new(nodes: nodes).endpoints).to eq [described_class::Node.new(0,1), described_class::Node.new(1,2)]
          end

          context "nodes are in descending order" do
            let(:nodes) { %w{1/2 0/1} }

            it "reorders the endpoints lesser to greater" do
              expect(described_class.new(nodes: nodes).endpoints).to eq [described_class::Node.new(0,1), described_class::Node.new(1,2)]
            end
          end

          context "nodes are not strings" do
            let(:nodes) { [0, 0.5] }

            it "recognizes it" do
              expect(described_class.new(nodes: nodes).endpoints).to eq [described_class::Node.new(0,1), described_class::Node.new(1,2)]
            end
          end
        end

        describe "node1 and node2" do
          let(:node1) { "0/1" }
          let(:node2) { "1/2" }

          it "recognizes it" do
            expect(described_class.new(node1: node1, node2: node2).endpoints).to eq [described_class::Node.new(0,1), described_class::Node.new(1,2)]
          end
        end


        describe "when node1 or node2 not strings" do
          let(:node1) { 0 }
          let(:node2) { 0.5 }

          it "recognizes it" do
            expect(described_class.new(node1: node1, node2: node2).endpoints).to eq [described_class::Node.new(0,1), described_class::Node.new(1,2)]
          end
        end

        describe "when node1 and node2 are in descending order" do
          let(:node1) { 0.5 }
          let(:node2) { 0 }

          it "reorders the endpoints lesser to greater" do
            expect(described_class.new(node1: node1, node2: node2).endpoints).to eq [described_class::Node.new(0,1), described_class::Node.new(1,2)]
          end
        end
      end
    end
  end

  describe "#endpoints" do
    it "are [(0/1), (1/0)] by default" do
      expect(described_class.new.endpoints).to eq [described_class::Node.new(0,1), described_class::Node.new(1,0)]
    end

    context "when tree keyword is stern_brocot or scale" do
      let(:tree_key) { %i{stern_brocot scale}.sample }

      it "endpoints are [(0/1), (1/0)]" do
        expect(described_class.new(tree_key).endpoints).to eq [described_class::Node.new(0,1), described_class::Node.new(1,0)]
      end
    end

    context "when tree keyword is octave_reduced" do
      let(:tree_key) { :octave_reduced }

      it "endpoints are [(1/1), (2/1)]" do
        expect(described_class.new(tree_key).endpoints).to eq [described_class::Node.new(1,1), described_class::Node.new(2,1)]
      end
    end

    context "when tree keyword is farey, keyboard, scale_step, or log2" do
      let(:tree_key) { %i{farey keyboard scale_step log2}.sample }

      it "endpoints are [(0/1), (1/1)]" do
        expect(described_class.new(tree_key).endpoints).to eq [described_class::Node.new(0,1), described_class::Node.new(1,1)]
      end
    end
  end

  describe "class constructors" do
    described_class::KNOWN_ENDPOINTS.each do |key, value|
      it "returns a #{key} fraction tree spanning the endpoints #{value}" do
        expect(described_class.send(key).endpoints).to eq value
      end
    end
  end

  describe "Validations" do
    # Between 0/1 and 1/0
    # FractionTree, Stern-Brocot, Scale
    #
    describe "Stern-Brocot endpoints" do
      subject { described_class.new }

      let(:number) { Rational(rand(100)+1, rand(100)+1) }
      it "accepts numbers from zero to fairly large ones" do
        expect{ subject.path_to(number) }.to_not raise_error
        expect{ subject.parents_of(number) }.to_not raise_error
        expect{ subject.descendancy_from(number) }.to_not raise_error
      end

      it "doesn't accept negative numbers" do
        expect{ subject.path_to(-1*number) }.to raise_error(ArgumentError, "-#{number} not in range of [(0/1), (1/0)]")
        expect{ subject.parents_of(-1*number) }.to raise_error(ArgumentError, "-#{number} not in range of [(0/1), (1/0)]")
        expect{ subject.descendancy_from(-1*number) }.to raise_error(ArgumentError, "-#{number} not in range of [(0/1), (1/0)]")
      end

      # Between 0/1 and 1/1
      # Farey, Keyboard, Scale step, Log2
      #
      context "Farey tree endpoints" do
        subject { described_class.new(:farey) }

        let(:number) { 7/1r }
        it "limits number to range [(0/1), (1/1)]" do
          expect{ subject.path_to(number) }.to raise_error(ArgumentError, "#{number} not in range of [(0/1), (1/1)]")
          expect{ subject.parents_of(number) }.to raise_error(ArgumentError, "#{number} not in range of [(0/1), (1/1)]")
          expect{ subject.descendancy_from(number) }.to raise_error(ArgumentError, "#{number} not in range of [(0/1), (1/1)]")
        end
      end

      # Between 1/1 and 2/1
      # Octave reduced
      #
      describe "Octave reduced tree" do
        subject { described_class.new(:octave_reduced) }

        let(:number) { [7/1r, 1/2r].sample }
        it "limits number to range [(1/1), (2/1)]" do
          expect{ subject.path_to(number) }.to raise_error(ArgumentError, "#{number} not in range of [(1/1), (2/1)]")
          expect{ subject.parents_of(number) }.to raise_error(ArgumentError, "#{number} not in range of [(1/1), (2/1)]")
          expect{ subject.descendancy_from(number) }.to raise_error(ArgumentError, "#{number} not in range of [(1/1), (2/1)]")
        end
      end
    end
  end

  describe "#quotient_walk" do
    # We limit the quotients for this test to 5. The default of 10 produces an array larger than needed for the tests.
    let(:limit) { 5 }

    context "Farey tree" do
      let(:number) { Math.log2(3/2r) }
      let(:expected_nodes) { [described_class::Node.new(0,1), described_class::Node.new(1,1), described_class::Node.new(1,2), described_class::Node.new(2,3), described_class::Node.new(3,5), described_class::Node.new(4,7), described_class::Node.new(7,12), described_class::Node.new(10,17)] }

      it "returns the fraction tree nodes leading to the log2 of number, by way of its continued fraction quotients" do
        expect(described_class.new(:farey).quotient_walk(number, limit: limit)).to eq expected_nodes
      end
    end

    context "octave reduced tree" do
      let(:number) { 2**(7.0/12) }
      # We limit the range of the returned list to the first 12 elements, for comparison purposes. The entire list is too long, otherwise.
      let(:subset_range) { (0..11) }
      let(:expected_nodes) { [described_class::Node.new(1,1), described_class::Node.new(2,1), described_class::Node.new(3,2), described_class::Node.new(4,3), described_class::Node.new(7,5), described_class::Node.new(10,7), described_class::Node.new(13,9), described_class::Node.new(16,11), described_class::Node.new(19,13), described_class::Node.new(22,15), described_class::Node.new(25,17), described_class::Node.new(28,19)] }

      it "returns the fraction tree nodes leading to the irrational number, by way of its continued fraction quotients" do
        expect(described_class.new(:octave_reduced).quotient_walk(number, limit: limit)[subset_range]).to eq expected_nodes
      end
    end
  end

  describe "#tree" do
    let(:expected_nodes) { [[described_class::Node.new(0,1), described_class::Node.new(1,0)], [described_class::Node.new(1,1)], [described_class::Node.new(1,2), described_class::Node.new(2,1)], [described_class::Node.new(1,3), described_class::Node.new(2,3), described_class::Node.new(3,2), described_class::Node.new(3,1)], [described_class::Node.new(1,4), described_class::Node.new(2,5), described_class::Node.new(3,5), described_class::Node.new(3,4), described_class::Node.new(4,3), described_class::Node.new(5,3), described_class::Node.new(5,2), described_class::Node.new(4,1)]] }
    let(:number) { 5 }

    it "returns a fraction tree that is n deep" do
      expect(described_class.new.tree(number)).to eq expected_nodes
      expect(described_class.new.tree(number).count).to eq number
    end
  end

  describe "#path_to" do
    context "with a number that is the same value as an endpoint" do
      let(:number) { [1, 2].sample }
      let(:expected_node) { described_class::Node.new(number,1) }

      it "returns the single endpoint node" do
        expect(described_class.new(:octave_reduced).path_to(number)).to eq expected_node
      end
    end

    context "with Rational" do
      let(:expected_nodes) { [described_class::Node.new(0,1), described_class::Node.new(1,0), described_class::Node.new(1,1), described_class::Node.new(2,1), described_class::Node.new(3,2), described_class::Node.new(4,3), described_class::Node.new(5,4), described_class::Node.new(6,5), described_class::Node.new(7,6), described_class::Node.new(8,7), described_class::Node.new(9,8), described_class::Node.new(10,9), described_class::Node.new(11,10)] }
      let(:number) { 11/10r }

      it "returns the list of nodes leading to n" do
        expect(described_class.new.path_to(number)).to eq expected_nodes
      end
    end

    context "with Float" do
      let(:number) { Math::PI }

      it "returns a large list reasonably quickly" do
        expect(described_class.new.path_to(number).count).to eq 414
        expect{ described_class.new.path_to(number) }.to perform_under(0.3).ms
      end

      context "with a Float of finite length" do
        let(:number) { 1.247265 }

        it "returns a list of reasonable length" do
          expect(described_class.new.path_to(number).count).to eq 62
        end
      end
    end
  end

  describe ".child_of" do
    context "with unrelated nodes" do
      it "returns nil" do
        expect(described_class.child_of(5/4r, 7/4r)).to eq nil
      end
    end

    context "with related nodes" do
      let(:expected_child_node) { described_class::Node.new(15,8) }
      it "returns the child node" do
        expect(described_class.child_of(13/7r, 2/1r)).to eq expected_child_node
      end
    end

    context "with strict farey overridden" do
      let(:expected_child_node) { described_class::Node.new(12,8) }

      it "returns a child of the non-Farey compliant parents" do
        expect(described_class.child_of(5/4r, 7/4r, strict_neighbors: false)).to eq expected_child_node
      end
    end
  end

  describe "#parents_of" do
    let(:expected_nodes) { [described_class::Node.new(8,7), described_class::Node.new(7,6)] }
    let(:number) { 15/13r }

    it "returns the parents of the fraction tree node" do
      expect(described_class.new.parents_of(number)).to eq expected_nodes
    end

    context "with Float of finite length" do
      let(:expected_nodes) { [ described_class::Node.new(47542,38117), described_class::Node.new(201911,161883)] }
      let(:number) { 1.247265 }

      it "returns the parents of 1247265/1000000 and not of 2808591094616131/2251799813685248" do
        expect(described_class.new.parents_of(number).inject(:+)).to eq expected_nodes.inject(:+)
      end
    end
  end

  describe "#common_ancestors_between" do
    let(:number1) { 7/6r }
    let(:number2) { 15/13r }
    let(:expected_nodes) { [described_class::Node.new(0,1), described_class::Node.new(1,0),described_class::Node.new(1,1), described_class::Node.new(2,1), described_class::Node.new(3,2), described_class::Node.new(4,3), described_class::Node.new(5,4), described_class::Node.new(6,5), described_class::Node.new(7,6)] }

    it "returns the nodes in common between the paths to the two numbers" do
      expect(described_class.new.common_ancestors_between(number1, number2)).to eq expected_nodes
    end
  end

  describe "#descendancy_from" do
    let(:number) { 5/4r }
    let(:depth) { 3 }
    let(:expected_nodes) { [described_class::Node.new(1,1), described_class::Node.new(7,6), described_class::Node.new(6,5), described_class::Node.new(11,9), described_class::Node.new(5,4), described_class::Node.new(14,11), described_class::Node.new(9,7), described_class::Node.new(13,10), described_class::Node.new(4,3)] }

    it "returns the decendents of number starting from its parents" do
      expect(described_class.new(:octave_reduced).descendancy_from(number, depth)).to eq expected_nodes
    end
  end

  describe "#sequence" do
    let(:depth) { 3 }
    let(:expected_nodes) { [described_class::Node.new(0,1), described_class::Node.new(1,3), described_class::Node.new(1,2), described_class::Node.new(2,3), described_class::Node.new(1,1), described_class::Node.new(3,2), described_class::Node.new(2,1), described_class::Node.new(3,1), described_class::Node.new(1,0)] }

    it "returns a sequence of fraction tree nodes" do
      expect(described_class.new.sequence(depth)).to eq expected_nodes
    end
  end

  describe "#descendants_of" do
    let(:parent1) { 1/1r }
    let(:parent2) { 4/3r }
    let(:depth) { 3 }
    let(:expected_nodes) { [described_class::Node.new(1,1), described_class::Node.new(7,6), described_class::Node.new(6,5), described_class::Node.new(11,9), described_class::Node.new(5,4), described_class::Node.new(14,11), described_class::Node.new(9,7), described_class::Node.new(13,10), described_class::Node.new(4,3)] }

    it "returns an array of nodes descended from parent1 and parent2" do
      expect(described_class.new.descendants_of(parent1, parent2, depth)).to eq expected_nodes
    end

    context "when parents are not farey related" do
      let(:parent2) { 7/4r }

      it "returns an empty array" do
        expect(described_class.new.descendants_of(parent1, parent2, depth)).to eq []
      end
    end

    context "when strict farey is overridden" do
      let(:parent2) { 7/4r }
      let(:expected_nodes) { [described_class::Node.new(1,1), described_class::Node.new(10,7), described_class::Node.new(9,6), described_class::Node.new(17,11), described_class::Node.new(8,5), described_class::Node.new(23,14), described_class::Node.new(15,9), described_class::Node.new(22,13), described_class::Node.new(7,4)] }

      it "returns an array of non-Farey compliant fractions" do
        expect(described_class.new.descendants_of(parent1, parent2, depth, strict_neighbors: false)).to eq expected_nodes
      end
    end
  end

  describe ".numeric_sequence" do
    let(:expected_sequence) { [1, 1, 2, 1, 3, 2, 3, 1, 4, 3, 5, 2] }
    let(:depth) { 12 }

    it "returns a sequence of fraction tree numerators" do
      expect(described_class.numeric_sequence.take(depth)).to eq expected_sequence
    end
  end

  describe ".farey_neighbors" do
    it "returns a sequence of Farey neighbors to the given number" do
      expect(described_class.farey_neighbors(5/4r)).to eq [(1/1r), (4/3r), (6/5r), (9/7r), (11/9r), (14/11r), (16/13r), (19/15r), (21/17r), (24/19r), (26/21r), (29/23r), (31/25r), (34/27r), (36/29r), (39/31r), (41/33r), (44/35r), (46/37r), (49/39r), (51/41r), (54/43r), (56/45r), (59/47r), (61/49r), (64/51r), (66/53r), (69/55r), (71/57r), (74/59r), (76/61r), (79/63r), (81/65r), (84/67r), (86/69r), (89/71r), (91/73r), (94/75r), (96/77r), (99/79r), (101/81r), (104/83r), (106/85r), (109/87r), (111/89r), (114/91r), (116/93r), (119/95r), (121/97r), (124/99r)]
    end
  end

  describe ".farey_neighbors?" do
    it "returns true if neighbors, false otherwise" do
      expect(described_class.farey_neighbors?(5/4r, 4/3r)).to eq true
      expect(described_class.farey_neighbors?(5/4r, 8/5r)).to eq false
    end
  end
end
