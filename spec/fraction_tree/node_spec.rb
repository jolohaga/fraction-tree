require "spec_helper"

RSpec.describe FractionTree::Node do
  describe "initialization" do
    let(:expected_node) { double("expected node", weight: 3/2r) }
    it "accepts two arguments" do
      expect(described_class.new(3,2)).to eq expected_node
    end
  end

  describe "ordering" do
    let(:node1) { described_class.new(4,3) }
    let(:node2) { described_class.new(3,2) }

    it "works as expected" do
      expect(node1).to be < node2
    end

    context "with (1/0)" do
      let(:node1) { described_class.new(1,0) }

      it "treats (1/0) as infinity" do
        expect(node1).to be > node2
        expect(node1.weight).to eq Float::INFINITY
      end
    end
  end

  describe ".+(n)" do
    let(:node1) { described_class.new(4,3) }
    let(:node2) { described_class.new(3,2) }
    let(:expected_result) { described_class.new(7,5) }

    it "does a mediant sum of the nodes" do
      expect(node1 + node2).to eq expected_result
    end

    context "with (1/0)" do
      let(:node2) { described_class.new(1,0) }
      let(:expected_result) { described_class.new(5,3) }

      it "does a mediant sum" do
        expect(node1 + node2).to eq expected_result
      end
    end
  end

  describe "String#to_node" do
    context "with numerics" do
      let(:string) { "1/2" }

      it "converts the string to a node with value (1/2)" do
        expect(string.to_node).to eq described_class.new(1,2)
      end
    end

    context "with multiple slashes" do
      let(:string) { "1/2/3" }

      it "converts the string to a node with value (1/2)" do
        expect(string.to_node).to eq described_class.new(1,2)
      end
    end

    context "with floats" do
      let(:string) { "3.141592653589793" }

      it "converts the string to a bigdecimal representation (3141592653589793,1000000000000000)" do
        expect(string.to_node).to eq described_class.new(3141592653589793,1000000000000000)
      end
    end

    context "with multiple decimal points" do
      let(:string) { "3.1415.92653589793" }

      it "converts the string to a node ignoring everything after the second decimal point (6283,2000)" do
        expect(string.to_node).to eq described_class.new(6283,2000)
      end
    end

    context "with alphabetics" do
      let(:string) { "a" }

      it "defaults to a node with value (0/1)" do
        expect(string.to_node).to eq described_class.new(0,1)
      end
    end

    context "with 0 in the denominator" do
      let(:string) { "1/0" }

      it "converts the string to a node with value (1/0)" do
        expect(string.to_node).to eq described_class.new(1,0)
      end
    end
  end
end
