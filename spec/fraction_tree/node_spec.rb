require "spec_helper"

RSpec.describe FractionTree::Node do
  describe ".new" do
    let(:expected_node) { double("expected node", number: 3/2r) }
    it "accepts one argument" do
      expect(described_class.new(3/2r)).to eq expected_node
    end
  end

  describe "ordering" do
    let(:node1) { described_class.new(4/3r) }
    let(:node2) { described_class.new(3/2r) }

    it "works as expected" do
      expect(node1).to be < node2
    end

    context "with (1/0)" do
      let(:node1) { described_class.new(Float::INFINITY) }

      it "treats (1/0) as infinity" do
        expect(node1).to be > node2
        expect(node1.number).to eq Float::INFINITY
      end
    end
  end

  describe ".decode" do
    it "returns the Node decoded from the string" do
      expect(described_class.decode("RLL")).to eq described_class.new(4/3r)
    end
  end

  describe ".encode" do
    it "returns the string encoding the node" do
      expect(described_class.encode(4/3r)).to eq "RLL"
    end
  end

  describe ".plus_minus" do
    it "returns a duple of positive and negative difference from number" do
      expect(described_class.plus_minus(3, 2)).to eq [1, 5]
    end
  end

  describe ".decimal_power" do
    it "returns the decimal power of the given number" do
      expect(described_class.decimal_power(1000)).to eq 3
    end
  end

  describe "#+(n)" do
    let(:node1) { described_class.new(4/3r) }
    let(:node2) { described_class.new(3/2r) }
    let(:expected_result) { described_class.new(7/5r) }

    it "does a mediant sum of the nodes" do
      expect(node1 + node2).to eq expected_result
    end

    context "with (1/0)" do
      let(:node2) { described_class.new(Float::INFINITY) }
      let(:expected_result) { described_class.new(5/3r) }

      it "does a mediant sum" do
        expect(node1 + node2).to eq expected_result
      end
    end
  end

  describe "#-(n)" do
    let(:node1) { described_class.new(4/3r) }
    let(:node2) { described_class.new(3/2r) }
    let(:expected_result) { described_class.new(1) }

    it "does a mediant subtraction of the nodes" do
      expect(node1 - node2).to eq expected_result
    end
  end

  describe "#path" do
    context "with a number that is the same value as the sum of the endpoints" do
      let(:number) { 1/1r }
      let(:expected_node) { [described_class.new(0/1r), described_class.new(Float::INFINITY), described_class.new(number)] }

      it "returns the tree nodes" do
        expect(described_class.new(number).path).to eq expected_node
      end
    end

    context "with Rational" do
      let(:expected_nodes) { [described_class.new(0), described_class.new(Float::INFINITY), described_class.new(1), described_class.new(2), described_class.new(3/2r), described_class.new(4/3r), described_class.new(5/4r), described_class.new(6/5r), described_class.new(7/6r), described_class.new(8/7r), described_class.new(9/8r), described_class.new(10/9r), described_class.new(11/10r)] }
      let(:number) { 11/10r }

      it "returns the list of nodes leading to n" do
        expect(described_class.new(number).path).to eq expected_nodes
      end
    end

    context "with a longer length BigDecimal" do
      let(:number) { Math::PI.to_d }

      it "returns a large list reasonably quickly" do
        expect(described_class.new(number).path.count).to eq 414
        expect{ described_class.new(number).path }.to perform_under(1.5).ms
      end

      context "with a shorter length BigDecimal" do
        let(:number) { 1.247265.to_d }

        it "returns a list of reasonable length" do
          expect(described_class.new(number).path.count).to eq 62
          expect{ described_class.new(number).path }.to perform_under(0.3).ms
        end
      end
    end
  end

  describe "#parents" do
    let(:number) { 15/13r }
    let(:expected_nodes) { [described_class.new(8/7r), described_class.new(7/6r)] }

    it "returns the parents of the fraction tree node" do
      expect(described_class.new(number).parents).to eq expected_nodes
    end

    context "with Float" do
      let(:expected_nodes) { [ described_class.new(1200632381750543/962612100676715r), described_class.new(1607958712865588/1289187713008533r)] }
      let(:number) { 1.247265 }

      it "returns the parents of 2808591094616131/2251799813685248" do
        expect(described_class.new(number).parents.inject(:+)).to eq expected_nodes.inject(:+)
      end
    end

    context "with BigDecimal" do
      let(:expected_nodes) { [ described_class.new(47542/38117r), described_class.new(201911/161883r)] }
      let(:number) { 1.247265.to_d }

      it "returns the parents of 1247265/1000000" do
        expect(described_class.new(number).parents.inject(:+)).to eq expected_nodes.inject(:+)
      end
    end
  end

  describe "#neighbors" do
    let(:number) { 5/4r }
    let(:expected_nodes) { [described_class.new(1/1r), described_class.new(4/3r), described_class.new(6/5r), described_class.new(9/7r), described_class.new(11/9r), described_class.new(14/11r), described_class.new(16/13r), described_class.new(19/15r), described_class.new(21/17r), described_class.new(24/19r), described_class.new(26/21r), described_class.new(29/23r), described_class.new(31/25r), described_class.new(34/27r), described_class.new(36/29r), described_class.new(39/31r), described_class.new(41/33r), described_class.new(44/35r), described_class.new(46/37r), described_class.new(49/39r), described_class.new(51/41r), described_class.new(54/43r), described_class.new(56/45r), described_class.new(59/47r), described_class.new(61/49r), described_class.new(64/51r), described_class.new(66/53r), described_class.new(69/55r), described_class.new(71/57r), described_class.new(74/59r), described_class.new(76/61r), described_class.new(79/63r), described_class.new(81/65r), described_class.new(84/67r), described_class.new(86/69r), described_class.new(89/71r), described_class.new(91/73r), described_class.new(94/75r), described_class.new(96/77r), described_class.new(99/79r), described_class.new(101/81r), described_class.new(104/83r), described_class.new(106/85r), described_class.new(109/87r), described_class.new(111/89r), described_class.new(114/91r), described_class.new(116/93r), described_class.new(119/95r), described_class.new(121/97r), described_class.new(124/99r)] }
    it "returns a sequence of Farey neighbors to the given number" do
      expect(described_class.new(number).neighbors).to eq expected_nodes
    end
  end

  describe "#common_ancestors_with" do
    let(:number1) { 7/6r }
    let(:number2) { 15/13r }
    let(:expected_nodes) { [described_class.new(0), described_class.new(Float::INFINITY),described_class.new(1), described_class.new(2), described_class.new(3/2r), described_class.new(4/3r), described_class.new(5/4r), described_class.new(6/5r), described_class.new(7/6r)] }

    it "returns the nodes in common between the paths to the two numbers" do
      expect(described_class.new(number1).common_ancestors_with(number2)).to eq expected_nodes
    end
  end

  describe "#descendancy_from" do
    let(:number) { 5/4r }
    let(:depth) { 3 }
    let(:expected_nodes) { [described_class.new(1/1r), described_class.new(7/6r), described_class.new(6/5r), described_class.new(11/9r), described_class.new(5/4r), described_class.new(14/11r), described_class.new(9/7r), described_class.new(13/10r), described_class.new(4/3r)] }

    it "returns the decendents of number starting from its parents" do
      expect(described_class.new(number).descendancy_from(depth: depth)).to eq expected_nodes
    end
  end

  describe "#child_with" do
    let(:number) { 4/3r }
    let(:partner) { 1/1r }
    let(:expected_nodes) { described_class.new(5/4r) }

    it "returns the child of self and the partner" do
      expect(described_class.new(number).child_with(partner)).to eq expected_nodes
    end
  end

  describe "#encoding" do
    it "returns the encoded string of self" do
      expect(described_class.new(4/3r).encoding).to eq "RLL"
    end
  end

  describe "Extensions" do
    describe "String#to_node" do
      context "with numerics" do
        let(:string) { "1/2" }

        it "converts the string to a node with value (1/2)" do
          expect(string.to_node).to eq described_class.new(1/2r)
        end
      end

      context "with multiple slashes" do
        let(:string) { "1/2/3" }

        it "converts the string to a node with value (1/2)" do
          expect(string.to_node).to eq described_class.new(1/2r)
        end
      end

      context "with floats" do
        let(:string) { "3.141592653589793" }

        it "converts the string to a bigdecimal representation (3141592653589793,1000000000000000)" do
          expect(string.to_node).to eq described_class.new(3141592653589793/1000000000000000r)
        end
      end

      context "with multiple decimal points" do
        let(:string) { "3.1415.92653589793" }

        it "converts the string to a node ignoring everything after the second decimal point (6283,2000)" do
          expect(string.to_node).to eq described_class.new(6283/2000r)
        end
      end

      context "with alphabetics" do
        let(:string) { "a" }

        it "defaults to a node with value (0/1)" do
          expect(string.to_node).to eq described_class.new(0)
        end
      end

      context "with 0 in the denominator" do
        let(:string) { "1/0" }

        it "converts the string to a node with value (1/0)" do
          expect(string.to_node).to eq described_class.new(Float::INFINITY)
        end
      end
    end

    describe "Numeric#to_node" do
      it "converts a numeric to a fraction tree node" do
        expect(Float::INFINITY.to_node).to be_a_kind_of(FractionTree::Node)
      end
    end
  end
end
