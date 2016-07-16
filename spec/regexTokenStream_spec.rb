require 'spec_helper'
require 'regexTokenStream'

describe RegexTokenStream do
	before :each do
		@stream = RegexTokenStream.new "#{File.dirname(__FILE__)}/data/regex_tokenStream"
	end

	describe "#new" do
		it "should take in a path to a token stream and return a RegexTokenStream object" do
			expect( @stream ).to be_instance_of RegexTokenStream
		end

		it "should fail if no file is given" do
			expect{ RegexTokenStream.new }.to raise_error(ArgumentError)
		end

		it "should fail if given file does not exist" do
			expect{ RegexTokenStream.new "some/fake/file" }.to raise_error(ArgumentError)
		end
	end

	describe "#parse" do
		it "should accept a string as an argument" do
			expect { @stream.parse "sample" }.to_not raise_error
			expect { @stream.parse }.to raise_error(ArgumentError)
		end

		context "should correctly parse a string" do
			it "and return an array of tokens" do
				expect( @stream.parse "(abc)" ).to be_instance_of Array
				expect( @stream.parse("(abc)").first ).to be_instance_of Token
				expect( @stream.parse("(abc)").length ).to eq 5
			end

			it "and have the correct tokens" do
				test_str = '(a\+c)'
				expect( @stream.parse(test_str)[0].type ).to eq "open"
				expect( @stream.parse(test_str)[0].value ).to eq nil

				expect( @stream.parse(test_str)[1].type ).to eq "char"
				expect( @stream.parse(test_str)[1].value ).to eq "a"

				expect( @stream.parse(test_str)[2].type ).to eq "char"
				expect( @stream.parse(test_str)[2].value ).to eq "+"
			end
		end
	end

	describe "#[]" do
		it "should return the correct tokens" do
			expect( @stream[0] ).to be_instance_of Token
			expect( @stream[0].type ).to eq("open")
			expect( @stream[0].value ).to eq(nil)

			expect( @stream[1] ).to be_instance_of Token
			expect( @stream[1].type ).to eq("char")
			expect( @stream[1].value ).to eq("a")

			expect( @stream[2] ).to be_instance_of Token
			expect( @stream[2].type ).to eq("char")
			expect( @stream[2].value ).to eq("+")
		end

		it "should have an end of stream token at the end" do
			expect( @stream.last.type ).to eq("$")
			expect( @stream.last.value ).to eq(nil)
		end
	end
end
