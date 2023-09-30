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
end
