require 'spec_helper'
require 'tokenStream'

describe TokenStream do
	before :each do
		@stream = TokenStream.new "#{File.dirname(__FILE__)}/data/test_tokenStream"
	end

	describe "#new" do
		it "should take in a path to a token stream and return a TokenStream object" do
			expect( @stream ).to be_instance_of TokenStream
		end

		it "should fail if no file is given" do
			expect{ TokenStream.new }.to raise_error(ArgumentError)
		end

		it "should fail if given file does not exist" do
			expect{ TokenStream.new "some/fake/file" }.to raise_error(ArgumentError)
		end
	end

	describe "#[]" do
		it "should return a token" do
			expect( @stream[0] ).to be_instance_of Token
			expect( @stream[0].type ).to eq("INT")
			expect( @stream[0].value ).to eq("4")
		end
	end
end

describe Token do
	before :each do
		@token = Token.new "type1", "a"
	end

	describe "#new" do
		it "should return a blank token with no arguments" do
			expect( Token.new ).to be_instance_of Token
		end

		it "should accept a type" do
			expect( Token.new "type1" ).to be_instance_of Token
		end

		it "should accept a type and a value" do
			expect( Token.new "type1", "b").to be_instance_of Token
		end
	end

	describe "#type" do
		it "should return the given type" do
			expect( @token.type ).to eq("type1")
		end
	end

	describe "#value" do
		it "should return the given value" do
			expect( @token.value ).to eq("a")
		end
	end
end
