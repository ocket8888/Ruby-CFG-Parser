require 'spec_helper'
require 'parseTree'
require 'ruby-graphviz'

describe ParseTree do
	before :each do
		@tree = ParseTree.new "root"
		@tree.add_child "a"
		@tree.add_child "b"
	end

	describe "#new" do
		it "should create a blank tree" do
			expect( ParseTree.new ).to be_instance_of ParseTree
		end
	end

	describe "#children" do
		it "should be an array" do
			expect( @tree.children ).to be_instance_of Array
		end

		it "should be an array of ParseTree objects" do
			expect( @tree.children.first ).to be_instance_of ParseTree
		end

		it "should have the expected values" do
			expect( @tree.children[0].value ).to eq("a")
			expect( @tree.children[1].value ).to eq("b")
		end
	end

	describe "#parent" do
		it "should see the expected parent" do
			expect( @tree.children.first.parent ).to be_instance_of ParseTree
			expect( @tree.children.first.parent.value ).to eq("root")
		end
	end

	describe "#value" do
		it "should return the expected value" do
			expect( @tree.value ).to eq("root")
		end
	end

	describe "#add_child" do
		it "should add a child to the node" do
			@tree.add_child "c"

			expect( @tree.children.map {|x| x.value}.sort ).to eq(%w{a b c})
			expect( @tree.children.last.value ).to eq("c")
			expect( @tree.children.last.parent.value ).to eq("root")
		end

		it "should return a copy of the new node" do
			expect( @tree.add_child "d" ).to be_instance_of ParseTree
		end

		it "should return false if given a nil argument" do
			expect( @tree.add_child nil ).to be false
		end
	end

	describe "#<<" do
		it "should add a child to the node" do
			@tree << "c"

			expect( @tree.children.map {|x| x.value}.sort ).to eq(%w{a b c}.sort)
			expect( @tree.children.last.value ).to eq("c")
			expect( @tree.children.last.parent.value ).to eq("root")
		end

		it "should return a copy of the new node" do
			expect( @tree << "d" ).to be_instance_of ParseTree
		end

		it "should return false if given a nil argument" do
			expect( @tree << nil ).to be false
		end
	end

	describe "#to_graphviz" do
		it "should return a graphviz tree object" do
			expect( @tree.to_graphviz ).to be_instance_of GraphViz
		end

		it "should accept a file path" do
			file = "#{File.dirname(__FILE__)}/data/generated_file.png"
			expect( @tree.to_graphviz file ).to be_instance_of GraphViz
			expect( File.exist? file ).to be true
		end

		it "should accept an optional file type to generate" do
			file = "#{File.dirname(__FILE__)}/data/generated_file.png"
			expect( @tree.to_graphviz file, type: "png" ).to be_instance_of GraphViz
			expect( File.exist? file ).to be true
		end
	end
end
