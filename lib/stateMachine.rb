class ShiftReduceConflictError < ArgumentError
end

class StateMachine
	attr_reader :transitions, :states
	def initialize
		@states = []
		@transitions = {}
	end

	def length
		return @states.length
	end

	def add state
		state = State.new state unless state.is_a? State

		if @states.include? state
			return false
		else
			@states << state
			return state
		end
	end

	def include? state
		state = State.new state unless state.is_a? State

		@states.include? state
	end

	def connect head, tail, symbol
		h = find(head)
		t = find(tail)

		raise ArgumentError, "State #{h.nil? ? head : tail} not found" if h.nil? or t.nil?
		@transitions[h] ||= {}

		raise ShiftReduceConflictError unless @transitions[h][symbol].nil?
		@transitions[h][symbol] = t

		return true
	end

	def children s
		index = find(s)

		results = []

		unless @transitions[index].nil?
			@transitions[index].values.each do |state|
				results << @states[state]
			end
		end

		return results
	end

	def parents s
		index = find(s)

		return @transitions.select do |k, children|
			children.values.include? index
		end.keys.map { |k| @states[k] }
	end

	def delete s
		index = find(s)
	end

	def find s
		s = State.new s unless s.is_a? State

		@states.index { |x| x.state == s.state }
	end

	def to_table
		table = []

		@states.each_index do |i|
			table << (@transitions[i].nil? ? {} : @transitions[i].clone)
		end

		return table
	end

	def [] index
		return @states[index]
	end
end

class State
	attr_accessor :state
	alias_method :eql?, :==

	def initialize state = nil
		@state = state
	end

	def ==(other_state)
		@state == other_state.state
	end

	def hash
		@state.hash
	end
end
