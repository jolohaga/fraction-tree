require "spec_helper"

RSpec.describe FractionTree do
  before(:each) do
    described_class.reset_nodes
    described_class.range = nil
  end

  describe ".range" do
    it "returns the range of the Stern-Brocot tree" do
      expect(described_class.range).to eq (0/1r..Float::INFINITY)
    end
  end

  describe ".range=" do
    it "accepts keywords" do
      described_class.range = :farey
      expect(described_class.range).to eq (0/1r..1/1r)
    end

    context "with nil" do
      it "resets to default" do
        described_class.range = :farey
        expect(described_class.range).to eq (0/1r..1/1r)
        described_class.range = nil
        expect(described_class.range).to eq (0/1r..Float::INFINITY)
      end
    end
  end

  describe ".left_node" do
    it "returns the left-most node of range" do
      expect(described_class.left_node).to eq 0/1r
    end
  end

  describe ".right_node" do
    it "returns the right-most node of range" do
      expect(described_class.right_node).to eq Float::INFINITY
    end
  end

  describe ".left_node=" do
    it "sets the left-most node of range" do
      described_class.left_node = 1/1r
      expect(described_class.left_node).to eq 1/1r
    end

    context "with nil" do
      it "resets to default" do
        described_class.left_node = 1/1r
        expect(described_class.left_node).to eq 1/1r
        described_class.left_node = nil
        expect(described_class.left_node).to eq 0/1r
      end
    end
  end

  describe ".right_node=" do
    it "sets the right-most node of range" do
      described_class.right_node = 2/1r
      expect(described_class.right_node).to eq 2/1r
    end

    context "with nil" do
      it "resets to default" do
        described_class.right_node = 2/1r
        expect(described_class.right_node).to eq 2/1r
        described_class.right_node = nil
        expect(described_class.right_node).to eq Float::INFINITY
      end
    end
  end

  describe ".node" do
    let(:node) { described_class.node(2/1r) }

    it "returns a FractionTree::Node" do
      expect(node).to be_a_kind_of(FractionTree::Node)
      expect(node.number).to eq 2/1r
    end
  end

  describe ".nodes" do
    it "returns the nodes cache, intended for internal use" do
      expect(described_class.nodes).to be_a_kind_of(Hash)
    end
  end

  describe ".reset_nodes" do
    it "resets the cache" do
      described_class.node(2/1r)
      expect(described_class.nodes.count).to eq 1
      described_class.reset_nodes
      expect(described_class.nodes.count).to eq 0
    end
  end

  describe ".decode" do
    it "returns the FractionTree::Node decoded from string" do
      expect(described_class.decode("LLR")).to eq described_class.node(2/5r)
    end
  end

  context ".mediant_sum" do
    let(:expected_node) { described_class::Node.new(12/8r) }

    it "returns the mediant sum of the two numbers" do
      expect(described_class.mediant_sum(5/4r, 7/4r)).to eq expected_node
    end
  end

  describe ".neighbors?" do
    let(:num1) { 5/4r }
    let(:num2) { 4/3r }

    context "when neighbors" do
      it "returns true" do
        expect(described_class.neighbors?(num1, num2)).to eq true
      end
    end

    context "when not neighbors" do
      let(:num1) { 5/4r }
      let(:num2) { 8/5r }

      it "returns false" do
        expect(described_class.neighbors?(num1, num2)).to eq false
      end
    end

    context "when infinity is considered" do
      let(:num1) { 2/1r }
      let(:num2) { Float::INFINITY }

      context "when neighbors" do
        it "returns true" do
          expect(described_class.neighbors?(num1, num2)).to eq true
        end
      end
    end
  end

  describe ".tree" do
    let(:expected_nodes) { [[described_class::Node.new(0), described_class::Node.new(Float::INFINITY)], [described_class::Node.new(1/1r)], [described_class::Node.new(1/2r), described_class::Node.new(2/1r)], [described_class::Node.new(1/3r), described_class::Node.new(2/3r), described_class::Node.new(3/2r), described_class::Node.new(3/1r)], [described_class::Node.new(1/4r), described_class::Node.new(2/5r), described_class::Node.new(3/5r), described_class::Node.new(3/4r), described_class::Node.new(4/3r), described_class::Node.new(5/3r), described_class::Node.new(5/2r), described_class::Node.new(4/1r)]] }
    let(:depth) { 5 }

    it "returns a fraction tree that is n deep" do
      expect(described_class.tree(depth: depth)).to eq expected_nodes
      expect(described_class.tree(depth: depth).count).to eq depth
    end
  end

  describe ".child_of" do
    context "with unrelated nodes" do
      it "returns nil" do
        expect(described_class.child_of(5/4r, 7/4r)).to eq nil
      end
    end

    context "with related nodes" do
      let(:expected_child_node) { described_class::Node.new(15/8r) }
      it "returns the child node" do
        expect(described_class.child_of(13/7r, 2/1r)).to eq expected_child_node
      end
    end
  end

  describe ".descendants_of" do
    let(:parent1) { 1/1r }
    let(:parent2) { 4/3r }
    let(:depth) { 3 }
    let(:expected_nodes) { [described_class::Node.new(1/1r), described_class::Node.new(7/6r), described_class::Node.new(6/5r), described_class::Node.new(11/9r), described_class::Node.new(5/4r), described_class::Node.new(14/11r), described_class::Node.new(9/7r), described_class::Node.new(13/10r), described_class::Node.new(4/3r)] }

    it "returns an array of nodes descended from parent1 and parent2" do
      expect(described_class.descendants_of(parent1, parent2, depth: depth)).to eq expected_nodes
    end

    context "when parents are not neighbor related" do
      let(:parent2) { 7/4r }

      it "returns an empty array" do
        expect(described_class.descendants_of(parent1, parent2, depth: depth)).to eq []
      end
    end
  end

  describe ".sequence" do
    let(:depth) { 3 }
    let(:expected_nodes) { [described_class::Node.new(0), described_class::Node.new(1/3r), described_class::Node.new(1/2r), described_class::Node.new(2/3r), described_class::Node.new(1/1r), described_class::Node.new(3/2r), described_class::Node.new(2/1r), described_class::Node.new(3/1r), described_class::Node.new(Float::INFINITY)] }

    it "returns a sequence of fraction tree nodes" do
      expect(described_class.sequence(depth: depth)).to eq expected_nodes
    end
  end

  describe ".numeric_sequence" do
    let(:expected_sequence) { [1, 1, 2, 1, 3, 2, 3, 1, 4, 3, 5, 2] }
    let(:depth) { 12 }

    it "returns a sequence of fraction tree numerators" do
      expect(described_class.numeric_sequence.take(depth)).to eq expected_sequence
    end
  end
end
