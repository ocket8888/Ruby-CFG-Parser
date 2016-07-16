require 'spec_helper'
require 'stateMachine'

describe StateMachine do
	before :each do
		@blank_machine = StateMachine.new
	end

	describe '#new' do
		it 'should create a blank state machine' do
			expect{ StateMachine.new }.not_to raise_error
		end
	end

	describe '#length' do
		it 'should return the number of states' do
			expect( @blank_machine.length ).to eq 0
		end
	end

	describe '#add' do
		it 'should have an add function' do
			expect( @blank_machine ).to respond_to :add
		end

		it 'should accept a State object' do
			expect{ @blank_machine.add State.new('something') }.not_to raise_error
		end

		it 'should accept a non-State object' do
			expect{ @blank_machine.add 'something else' }.not_to raise_error
		end

		it 'should increase the number of states' do
			expect{ @blank_machine.add 'some state' }.to change{@blank_machine.length}.from(0).to(1)
		end

		it 'should not add if it already exists' do
			@blank_machine.add 'clone'
			expect{ @blank_machine.add 'clone' }.not_to change{ @blank_machine.length }
		end

		it 'should return false if it already exists' do
			@blank_machine.add 'clone'
			expect( @blank_machine.add 'clone' ).to be false
		end
	end

	describe '#include?' do
		before :each do
			@blank_machine.add 'needle'
		end

		it 'should return true if the state exists' do
			expect( @blank_machine.include? 'needle' ).to be true
		end

		it 'should return false if the state does not exist' do
			expect( @blank_machine.include? 'haystack' ).to be false
		end
	end

	describe '#connect' do
		before :each do
			@blank_machine.add 'First state'
			@blank_machine.add 'Second state'
		end

		it 'should accept two states to connect' do
			expect{ @blank_machine.connect }.to raise_error(ArgumentError)
			expect{ @blank_machine.connect('First state') }.to raise_error(ArgumentError)
			expect{ @blank_machine.connect('First state', 'Second state', 'b') }.not_to raise_error
		end

		it 'should raise an error when a conflict occurs' do
			@blank_machine.connect('First state', 'Second state', 'b')
			@blank_machine.add('Third state')
			
			expect{ @blank_machine.connect('First state', 'Third state', 'b') }.to raise_error(ShiftReduceConflictError)
		end
	end

	context 'to follow relationships' do

		before :each do
			%w{ first second third }.each do |s|
				@blank_machine.add s
			end

			@blank_machine.connect('first', 'second', 'b')
			@blank_machine.connect('first', 'third', 'c')
		end

		describe '#children' do

			it "should accept a state" do
				expect{ @blank_machine.children(State.new('first')) }.not_to raise_error
				expect{ @blank_machine.children('first') }.not_to raise_error
			end

			it "should return only the expected children" do
				expect( @blank_machine.children('first').map {|s| s.state} ).to match_array ['second', 'third']
				expect( @blank_machine.children('second') ).to be_empty
				expect( @blank_machine.children('third') ).to be_empty
			end
		end

		describe '#parents' do
			it "should accept a state" do
				expect{ @blank_machine.parents(State.new('first')) }.not_to raise_error
				expect{ @blank_machine.parents('first') }.not_to raise_error
			end

			it "should return only the expected parents" do
				expect( @blank_machine.parents('first') ).to be_empty
				expect( @blank_machine.parents('second').map {|x| x.state} ).to match_array ['first']
				expect( @blank_machine.parents('third').map {|x| x.state} ).to match_array ['first']
			end
		end
	end

	describe '#delete' do
		before :each do
			%w{ first second third }.each do |s|
				@blank_machine.add s
			end

			@blank_machine.connect('first', 'second', 'b')
			@blank_machine.connect('first', 'third', 'c')
		end

		it 'should delete the given state' do
			expect{ @blank_machine.delete 'first' }.to change{@blank_machine.length}.from(3).to(2)
		end

		it 'should delete all transitions from this state' do
			expect{ @blank_machine.delete 'second' }.to change{ @blank_machine.children('first').length }.from(2).to(1)
		end

		it 'should delete all transitions to this state' do
			expect{ @blank_machine.delete 'second' }.to change{ @blank_machine.children('first').length }.from(2).to(1)
		end
	end

	describe '#to_table' do
		before :each do
			%w{ first second third }.each do |s|
				@blank_machine.add s
			end

			@blank_machine.connect('first', 'second', 'a')
			@blank_machine.connect('first', 'third', 'b')
		end

		it 'should return the expected data format' do 
			expect( @blank_machine.to_table ).to be_instance_of Array
			expect( @blank_machine.to_table.first ).to be_instance_of Hash
		end

		it 'should return the expected table' do
			expected = [
				{
					'a'=> 1,
					'b' => 2,
				},
				{
				},
				{
				}
			]

			expect( @blank_machine.to_table ).to eq expected
		end
	end

	describe '#[]' do
		before :each do
			%w{ first second third }.each do |s|
				@blank_machine.add s
			end
		end

		it 'should return the correct state given an index' do
			expect(@blank_machine[0]).to be_instance_of State
			expect(@blank_machine[0].state).to eq 'first'
			expect(@blank_machine[1].state).to eq 'second'
			expect(@blank_machine[2].state).to eq 'third'
		end
	end
end

describe State do
	describe '#new' do
		it "should not fail to create a new object" do
			expect{ State.new }.not_to raise_error
			expect( State.new ).to be_instance_of State
		end

		it "should optionally accept a value for the state" do
			expect( State.new 'My first state' ).to be_instance_of State
		end
	end

	describe '#==' do
		before :each do
			@first = State.new 'some state'
			@second = State.new 'some state'
			@third = State.new 'other state'
		end

		it 'should evaluate equality' do
			expect(@first).to be == @second
			expect(@first).not_to be == @third
		end
	end
end
