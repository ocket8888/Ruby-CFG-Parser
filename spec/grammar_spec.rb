require 'spec_helper'
require 'grammar'
require 'stateMachine'

# This test file describes the functionality of the Grammar object using the RSpec testing framework. Make sure your "do"s and "end"s
# match up. The before block runs before each test (can be replaced with :all but you shouldn't need to) so any set up goes there.
# Resources like the test grammar are in the data directory. For examples on expectations (expect(...).to be_something) see
# https://www.relishapp.com/rspec/rspec-expectations/docs/built-in-matchers
# To run these tests just run RSpec in a command line

describe Grammar do
	before :each do
		# __FILE__ is a special variable that refers to the current file, spec/grammar_spec.rb in this case
		# File.dirname gets the directory. It will return spec/ in this case. I do this so you don't have to run
		# the tests from a certain directory
		@grammar = Grammar.new "#{File.dirname(__FILE__)}/data/test_grammar"
		@blank_grammar = Grammar.new "#{File.dirname(__FILE__)}/data/blank_grammar"
	end

	describe "#new" do
		it "takes a path to a grammar file and returns a Grammar object" do
			expect(@grammar).to be_instance_of Grammar
		end

		it "should fail if no grammar file passed" do
			expect { Grammar.new }.to raise_error(ArgumentError)
		end

		it "should fail if given grammar file does not exist" do
			file = "#{File.dirname(__FILE__)}/some_fake_file"
			expect(file).to satisfy { |v| File.exist?(v) == false }
			expect { Grammar.new file }.to raise_error(ArgumentError)
		end
	end

	describe "#non_terminals" do
		it "should return non_terminals in the grammar" do
			expect( @grammar.non_terminals ).to be_instance_of Array
			expect( @grammar.non_terminals ).to match_array(%w{S A T VAR E})
		end
	end

	describe "#terminals" do
		it "should return terminals in the grammar" do
			expect( @grammar.terminals ).to be_instance_of Array
			expect( @grammar.terminals ).to match_array(%w{a b e equal f g h j k plus s t times zero $})
		end
	end

	describe "#goal_symbol" do
		it "should return detected goal symbol" do
			expect( @grammar.goal_symbol ).to be_instance_of String
			expect( @grammar.goal_symbol ).to eq("S")

			expect( @grammar.goal ).to be_instance_of String
			expect( @grammar.goal ).to eq("S")
		end
	end

	describe "#rules" do
		it "should return the expected rules" do
			rules = {
				"S"	=> [%w{A $}],
				"A"	=> [%w{T A}, %w{lambda}],
				"T"	=> [%w{VAR equal E}],
				"VAR"	=> [%w{e}, %w{f}, %w{g}, %w{h}, %w{j}, %w{k}],
				"E"	=> [%w{a plus b}, %w{s times t}, %w{zero}, %w{VAR}]
			}
			expect( @grammar.rules ).to be_instance_of Hash
			expect( @grammar.rules ).to eq(rules)

			expect( @grammar.production_rules ).to be_instance_of Hash
			expect( @grammar.production_rules ).to eq(rules)
		end
	end

=begin
	describe "#to_s" do
		it "should return a string" do
			#sample_output = "Terminals: S, A, T, E, VAR\nNon-terminals: equal, a, plus, b, s, times, t, zero, e, f, g, h, j, k\n\nGrammar Rules\n(1)   S -> A $\n(2)   A -> T A\n(3)   A -> lambda\n(4)   T -> VAR equal E\n(5)   E -> a plus b\n(6)   E -> s times t\n(7)   E -> zero\n(8)   E -> VAR\n(9)   VAR -> e\n(10)   VAR -> f\n(11)   VAR -> g\n(12)   VAR -> h\n(13)   VAR -> j\n(14)   VAR -> k\n\nGrammar Start Symbol: S"
			sample_output = "Terminals: equal, a, plus, b, s, times, t, zero, e, f, g, h, j, k\nNon-terminals: S, A, T, E, VAR\n\nGrammar Rules\n(1)   S -> A $\n(2)   A -> T A\n(3)   A -> lambda\n(4)   T -> VAR equal E\n(5)   E -> a plus b\n(6)   E -> s times t\n(7)   E -> zero\n(8)   E -> VAR\n(9)   VAR -> e\n(10)   VAR -> f\n(11)   VAR -> g\n(12)   VAR -> h\n(13)   VAR -> j\n(14)   VAR -> k\n\nGrammar Start Symbol: S\n\nDerives to lambda: A\n\nFirst sets:\nFirst(S)= \nFirst(A)= \nFirst(T)= \nFirst(E)= \nFirst(VAR)=\n\nFollow sets:\nFollow(S)= \nFollow(A)= \nFollow(T)= \nFollow(E)= \nFollow(VAR)="
			expect( @grammar.to_s ).to be_instance_of String
			expect( @grammar.to_s ).to eq(sample_output)
		end
	end
=end

	describe "#derives_to_lambda?" do
		it "should return false if no production rules are found" do
			expect( @blank_grammar.rules ).to be_empty
			expect( @blank_grammar.derives_to_lambda? ).to be false
		end

		it "should return true with test_grammar" do
			expect( @grammar.derives_to_lambda? ).to be true
		end
	end

	describe "#first_set" do
		it "should return false if no production rules are found" do
			expect( @blank_grammar.first_set ).to eq([])
		end

		it "should return the valid first set for a given grammar" do
			expected_set = ['e', 'f', 'g', 'h', 'j', 'k', '$'].sort
			expect( @grammar.first_set.sort ).to eq(expected_set)

		end
	end

	describe "#follow_set" do
		it "should return an empty set if no production rules are found" do
			blank_grammar = Grammar.new "#{File.dirname(__FILE__)}/data/blank_grammar"
			expect( blank_grammar.rules ).to be_empty
			expect( blank_grammar.follow_set "C" ).to be_instance_of Array
			expect( blank_grammar.follow_set("C").first ).to be_empty 
		end

		it "should return an array with a valid follow set with test_grammar" do
			grammar3 = Grammar.new "#{File.dirname(__FILE__)}/data/test_grammar3"
			expect( grammar3.follow_set("B").first ).to be_instance_of Array
			expect( grammar3.follow_set("B", []).first.sort ).to eq(["q","c","d", "$"].sort)
		end
	end

	describe "#ll_table" do
		it "should return a hash" do
			expect( @grammar.ll_table ).to be_instance_of Hash
		end

		it "should return an empty hash" do
			blank_grammar = Grammar.new "#{File.dirname(__FILE__)}/data/blank_grammar"
			expect( blank_grammar.ll_table ).to be_instance_of Hash
			expect( blank_grammar.ll_table ).to be_empty
		end

		it "should return the expected LL(1) table" do
			#rules = {
			#	"S"	=> [%w{A $}],
			#	"A"	=> [%w{T A}, %w{lambda}],
			#	"T"	=> [%w{VAR equal E}],
			#	"VAR"	=> [%w{e}, %w{f}, %w{g}, %w{h}, %w{j}, %w{k}],
			#	"E"	=> [%w{a plus b}, %w{s times t}, %w{zero}, %w{VAR}]
			#}
			expected_table = {
				"S" => {
					"e" => 0,
					"f" => 0,
					"g" => 0,
					"h" => 0,
					"j" => 0,
					"k" => 0,
					"$" => 0
				},
				"A" => {
					"e" => 0,
					"f" => 0,
					"g" => 0,
					"h" => 0,
					"j" => 0,
					"k" => 0,
					"$" => 1
				},
				"T" => {
					"e" => 0,
					"f" => 0,
					"g" => 0,
					"h" => 0,
					"j" => 0,
					"k" => 0
				},
				"E" => {
					"a" => 0,
					"s" => 1,
					"zero" => 2,
					"e" => 3,
					"f" => 3,
					"g" => 3,
					"h" => 3,
					"j" => 3,
					"k" => 3
				},
				"VAR" => {
					"e" => 0,
					"f" => 1,
					"g" => 2,
					"h" => 3,
					"j" => 4,
					"k" => 5
				}
			}

			expect( @grammar.ll_table ).to eq( expected_table );
		end
	end

	describe "#makeTree" do
		it "should return the root of the parse tree" do
			grammar3 = Grammar.new "#{File.dirname(__FILE__)}/data/test_grammar3"
			stream = TokenStream.new "#{File.dirname(__FILE__)}/data/test_tokenStream_grammar3"
			expect( grammar3.makeTree stream).to be_instance_of ParseTree
		end
	end

	describe "#goto" do
		it "should return the expected item set" do
			input = {
				'Start'	=> [
					%w{ . E $ }
				],
				'E'	=> [
					%w{ . plus E E },
					%w{ . num }
				]
			}

			output = {
				'E'	=> [
					%w{ plus . E E },
					%w{ . plus E E },
					%w{ . num }
				]
			}

			grammar = Grammar.new "#{File.dirname(__FILE__)}/data/test_grammar5"
			expect(grammar.goto(input, 'plus')).to eq output
		end
	end

	describe "#closure" do
		it "should compute the closure of the initial item set" do
			starting_item_set = { 
				"S" => [%w{. A $}],
			}
			ending_item_set = {
				"S" => [%w{. A $}],
				"A" => [%w{. T A}, %w{. lambda}],
				"T" => [%w{. VAR equal E}],
				"VAR" => [%w{. e}, %w{. f}, %w{. g}, %w{. h}, %w{. j}, %w{. k}],
			}
			expect( @grammar.closure starting_item_set ).to eq( ending_item_set )
		end
		it "should correctly compute the closure of an item set that we have already made some progress in" do
			grammar3 = Grammar.new "#{File.dirname(__FILE__)}/data/test_grammar3"
			starting_item_set = {
				"S" => [%w{A . C $}],
			}
			ending_item_set = {
				"S" => [%w{A . C $}],
				"C" => [%w{. c}, %w{. lambda}],
			}
			expect( grammar3.closure starting_item_set ).to eq( ending_item_set )
		end

		it "should correctly compute the closure of an item set that does not include the start symbol" do
			starting_item_set = {
				"T" => [%w{VAR equal . E}],
			}
			ending_item_set = {
				"T" => [%w{VAR equal . E}],
				"E" => [%w{. a plus b}, %w{. s times t}, %w{. zero}, %w{. VAR}],
				"VAR" => [%w{. e}, %w{. f}, %w{. g}, %w{. h}, %w{. j}, %w{. k}],
			}
			expect( @grammar.closure starting_item_set ).to eq( ending_item_set )
		end
	end

	describe "#slr_table" do
		before :each do
			@slr_grammar = Grammar.new "#{File.dirname(__FILE__)}/data/test_grammar_slr"
		end

		it "should return a table data structure" do
			expect( @slr_grammar.slr_table ).not_to be_instance_of StateMachine
			expect( @slr_grammar.slr_table ).to be_instance_of Array
			expect( @slr_grammar.slr_table.first ).to be_instance_of Hash
		end

		it "should match the expected table" do
			slr_table = [
				{
					# state 0
					'num' => 1,
					'Start' => 'accept',
					'E' => 2,
					'T' => 3
				},
				{
					# state 1
					'plus' => 'E,1',
					'times' => 6,
					'$' => 'E,1',
				},
				{
					# state 2
					'plus' => 'T,1',
					'times' => 'T,1',
					'$' => 'T,1'
				},
				{
					# state 3
					'plus' => 5,
					'$' => 4
				},
				{
					# state 4
					'num' => 1,
					'T' => 7
				},
				{
					# state 5
					'$' => 'Start,0'
				},
				{
					# state 6
					'plus' => 'E,0',
					'times' => 6,
					'$' => 'E,0'
				},
				{
					# state 7
					'num' => 8
				},
				{
					# state 8
					'plus' => 'T,0',
					'times' => 'T,0',
					'$' => 'T,0'
				}
			]

			expect( @slr_grammar.slr_table ).to match_array slr_table
		end
	end
end
