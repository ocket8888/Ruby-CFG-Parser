require 'tokenStream'
require 'parseTree'
require 'stateMachine'

class Grammar
	# automatic getters, and methods. So you can use either g.goal_symbol or g.goal to do the same thing
	attr_reader :goal, :production_rules
	alias_method :goal_symbol, :goal
	alias_method :rules, :production_rules

	# This function is the constructor for the object.
	# A variable with an @ at the front makes it an attribute variable. Without the @ the variable
	# is only in the scope of the function
	def initialize file_path
		raise ArgumentError if file_path.nil? or not File.exist?(file_path)

		# Read the file as an array of strings (each line is an entry in the array) and remove unneeded whitespace
		@grammar_string = File.readlines(file_path).map { |x| x.strip }
		@production_rules = {}

		#a variable for the marker we use in LR parsing
		@marker = "."

		parse_grammar
	end

	def derives_to_lambda?(non_term=@goal)
		# if not @production_rules.has_key?(non_term) 
		# raise ArgumentError, "Invalid argument for Derives to Lambda (#{non_term}). No production rules exist."
		# end
		return false if @production_rules.empty? or terminals.include? non_term 
		return true if non_term == 'lambda'
		dtl_recurse(non_term, [])
	end


	def first_set(val=@goal)
		first, = first_set_recursive(val)
		return first
	end

	def follow_set non_term, s=[]
		if s.include? non_term then return [], s; end		

		s << non_term
		f = []
		#Look at every production rule that we know
		@production_rules.each_key do |k|
			@production_rules[k].each do |j|

				if j.include? non_term #Ensures that A is on the RHS of production rule j
					j.each_index do |i|
						if j[i] == non_term
							xb = j[i+1, j.length]
							g = first_set(xb)
							g.each do |gg| #f \union G
								f << gg
							end
							allDerivesToLambda = true
							xb.each do |x|
								if non_terminals.include? x
									if !derives_to_lambda?(x) then allDerivesToLambda = false; end
								else
									allDerivesToLambda = false
								end
							end
							if allDerivesToLambda
								g,s = follow_set(k, s)
								g.each do |gg| #f \union G
									f << gg
								end
							end
						end
					end
				end

			end
		end
		return f.uniq, s
	end

	# Returns if all non-terms have unique predicts for each rule
	def disjoint_test
		returnValue = true
		@production_rules.each_key do |non_term|
			predict_sets = predict_sets(non_term)
			predict_sets.each_index do |index|
				for sercond_index in (index+1)..(predict_sets.length-1)
					if(predict_sets[index] & predict_sets[sercond_index] != [])
						#predict sets overlap, return false
						print "Predict sets of #{non_term} overlap. Rule #{index} and #{sercond_index}\n"
						returnValue =  false
					end
				end
			end
		end
		return returnValue
	end

	# Return the predict set for each rule for a given non-term(inal)
	def predict_sets non_term
		returnList = []
		@production_rules[non_term].each do |rule|
			predict_set = first_set(rule)
			allDerivesToLambda = true
			rule.each do |term|
				if !derives_to_lambda?(term)
					allDerivesToLambda = false
				end
			end
			if allDerivesToLambda
				#print "follow_set of #{non_term} = #{follow_set(non_term)[0]}\n"
				predict_set = predict_set + follow_set(non_term)[0]
			end
			returnList << predict_set.uniq
		end 
		return returnList
	end

	# Return all terminals in the grammar
	def terminals
		return @production_rules.values.flatten.uniq.select { |x| /([a-z]+|\$)/ =~ x  and x != "lambda" }
	end

	# Return all non-terminals in a grammar. Exclude lambda
	def non_terminals
		return @production_rules.keys
	end

	# Generate a string that accurately describes this object. This string is the output for the CLI
	def to_s
		[
			"Terminals: #{terminals.join(', ')}",
			"Non-terminals: #{non_terminals.join(', ')}",
			"\nGrammar Rules",
				print_rules,
				"\nGrammar Start Symbol: #{@goal}",
			"\nDerives to lambda: #{print_lambda}",
			"\nFirst sets:",
				print_firsts,
				"\nFollow sets:",
				print_follows,
				"\nPredict sets:",
				print_predicts

		].join("\n")
	end

	# generate the ll(1) parse table
	def ll_table
		table = {}
		non_terminals.each do |non_term|
			table[non_term] = {}
			p_sets = predict_sets(non_term)
			p_sets.each_index do |i|
				p_sets[i].each do |term|
					table[non_term][term] = i
				end
			end
		end

		return table
	end

	def slr_table
		states = StateMachine.new
		workList = []

		#get inital item set
		startItems = {}
		# I don't like this Marshal unMarshal pattern, but I don't have a better solution. Food for thought
		startItems[@goal] = Marshal.load(Marshal.dump(@production_rules[@goal]))
		startItems[@goal].map! { |r| r.unshift @marker }

		fresh_sym = []
		
		loop do
			original = fresh_sym.clone
			fresh_sym.each do |sym|
				startItems[sym] = Marshal.load(Marshal.dump(@production_rules[sym])).map { |r| r.unshift @marker }
			end

			startItems.each do |sym, rules|
				rules.each do |r|
					mark = r.index( @marker )
					if non_terminals.include? r[mark+1]
						fresh_sym << r[mark+1]
					end
				end
			end
			fresh_sym.uniq!

			# break if it hasn't changed
			break if fresh_sym == original
		end

		workList << startItems

		# Add shifts
		until workList.empty?
			s = workList.shift

			currentState = if states.include? s
					       states[states.find s]
				       else
					       states.add s
				       end

			for x in (terminals + non_terminals)
				newState = goto(Marshal.load(Marshal.dump(currentState.state)), x)
				
				if newState.empty?
					states
				else 
					if a = states.add(newState) then workList << a end
					states.connect(currentState, newState, x)
				end
			end
		end

		# populate reductions
		return completeTable(states)
	end

	#Makes a tree for the given token stream using the current grammar
	def makeTree ts
		ts.reverse
		llt = ll_table
		p = @production_rules
		t = ParseTree.new "root"
		cur = t
		k = [@goal]
		while k.length > 0
			x = k.pop
			if non_terminals.include? x
				#Next token may not predict a p in P, must look for top of token stream in cur's predict set
				ruleNumber = llt[x][ts[-1].type]
				raise "Couldn't find production rules for #{ts[-1].type} for the non-terminal #{x}" if ruleNumber.nil?
				k << '*'
				r = p[x][ruleNumber]
				r.reverse.each {|term| k << term}
				cur << x
				cur = cur.children[-1]
			elsif ((terminals.include? x) or (x == 'lambda'))
				if terminals.include? x
					raise "\'#{x}\' is a terminal, but we expected \'#{x}\' to be \'#{ts[-1].type}\'" if x != ts[-1].type
					a = ts.tokens.pop #this is probably a string
					cur << a
				else
					cur << x
				end


			elsif x == '*'
				cur = cur.parent
			end
		end
		return t.children[0]
	end

	def get_item_sets
		start_set = Hash.new
		start_set[@goal] = []

		# Add fresh starts for all production rules for goal
		@production_rules[@goal].each do |rule|
			rule_copy = rule.clone
			rule_copy.unshift @marker
			start_set[@goal].push(rule_copy)
		end

		symbols = terminals + non_terminals

		# Add the closure of the starting items to the item sets
		item_sets = Set.new
		item_sets.add(closure(start_set))


		# Find new item sets while more are still being added
		new_set_found = true
		while new_set_found
			new_set_found = false

			# Make a new set to avoid adding to the overall set while iterating
			new_item_sets = Set.new

			# Check each item set with each symbol
			item_sets.each do |item_set|
				symbols.each do |sym|

					# Compute the closure of the item set and symbol (need to deep copy to prevent modification)
					new_set = goto(Marshal.load(Marshal.dump(item_set)), sym)

					# If a new set was found, add it to the new sets
					if not new_set.empty? and not item_sets.include?(new_set)
						new_set_found = true
						new_item_sets.add(new_set)
					end
				end
			end

			# Add the sets found this iteration to the overall item sets
			item_sets += new_item_sets
		end

		return item_sets
	end

	#Calculate the closure of an itemset
	#item_set: a Hash where keys are the lhs of the rules in a grammar and values are a list of lists
	#containing rhs of a particular non-terminal (the rhs should also have markers placed in them)
	#returns result which is similar to item_set in structure
	def closure item_set
		result = item_set
		temp = nil
		#continue adding to closure set until it doesn't change
		until temp == result
			#create deep copy of temp
			temp = Marshal.load(Marshal.dump(result))
			temp.keys.each do |lhs|
				temp[lhs].each do |rhs|
					if rhs.index(@marker)
						next_val = rhs[rhs.index(@marker)+1]
						if non_terminals.include?(next_val)
							@production_rules[next_val].each do |rhs|
								#create temporary rhs so we don't modify the production rules with unshift
								t_rhs = rhs.clone
								t_rhs = t_rhs.unshift(@marker)
								if result[next_val]
									dup = false
									result[next_val].each do |r|
										if r.eql?(t_rhs)
											dup = true
											break
										end
									end
									if !dup
										result[next_val].push(t_rhs)
									end
								else
									result[next_val] = [t_rhs]
								end
							end
						end
					end
				end
			end
		end
		return result
	end

	def goto item_set, symbol
		raise ArgumentError, "Unexpected Item set: #{item_set.inspect}" unless item_set.is_a? Hash

		advance_set = {}

		# Create item set K in the GoTo algorithm
		item_set.each do |k, rules|
			# filter out rules
			filtered = rules.select { |arr| arr[arr.index(@marker)+1] == symbol }
			next if filtered.empty?

			# advance mark past symbol
			filtered.each do |rule|
				index = rule.index(@marker)

				rule[index] = rule[index+1]
				rule[index+1] = @marker
			end

			advance_set[k] = filtered
		end

		return closure(advance_set)
	end

	private

	def dtl_recurse(non_term=@goal, stack=[])
		@production_rules[non_term].each do |rhs|
			return true if rhs == ["lambda"]

			next unless rhs.index { |p| p != "$" and terminals.include? p }.nil?

			allderive = true
			rhs.each do |x|
				next if x == "$" or stack.include? [non_term, rhs, x]

				stack.push [non_term, rhs, x]
				allderive = dtl_recurse(x, stack)
				stack.pop

				break unless allderive
			end
			return true if allderive
		end
		return false
	end

	def first_set_recursive(prod, set=[])
		set.uniq!
		prod = [prod].flatten # ensure prod is an Array
		top = prod.shift
		return [top], set if terminals.include? top
		return [], set if top == "$" or top == "lambda" or top.nil?

		temp = []
		unless set.include? top
			set << top
			@production_rules[top].each do |p|
				n, new_set = first_set_recursive(p, set)
				temp += n
			end
		end

		if derives_to_lambda? top
			n, set = first_set_recursive(prod, set)
			temp += n
		end

		return temp, set
	end

	# parse the grammar string read in from the file
	def parse_grammar 
		normalize

		@grammar_string.each do |line|
			lhs, placeholder, rhs = line.partition "->"
			# get rid of extra white space
			lhs.strip!
			rhs.strip!

			# catch line with goal symbol
			@goal = lhs if rhs.include? "$"

			rhs.split("|").each do |rule|
				@production_rules[lhs] ||= []
				@production_rules[lhs] << rule.split(" ")
			end
		end
	end

	# normalize the grammar. Move up all values that start with an "|" to their respective production rules
	# Ensures that every entry in the grammar array is one full production rule with a "->" character
	def normalize
		@grammar_string.each_index do |i|
			temp = @grammar_string[i]
			if temp.empty?
				@grammar_string[i] = nil
			elsif temp[0] == "#"
				#continue 
				next
			elsif temp[0] == "|"
				last = i
				begin
					last -= 1
				end while @grammar_string[last].nil?

				@grammar_string[last] += " #{temp}"
				@grammar_string[i] = nil
			end
		end

		@grammar_string.compact!
	end

	# convert the production rules into a printable string
	def print_rules
		queue = [@goal]
		visited = []
		count = 0
		rule_string = ""
		term = non_terminals

		until queue.empty?
			prod = queue.pop
			visited.push prod

			@production_rules[prod].each do |rule|
				count += 1

				rule_string += "(#{count})   #{prod} -> #{rule.join(" ")}\n"
				rule.each { |r| queue.push r if term.include? r and not visited.include? r }
			end
			queue.uniq!
		end
		rule_string.strip!
		return rule_string
	end

	def print_lambda
		queue = [@goal]
		_lambda = []
		visited = []
		lambda_string = ""
		term = non_terminals


		until queue.empty?
			prod = queue.pop
			visited.push prod
			if prod != @goal and derives_to_lambda? prod
				_lambda.push prod
			end
			@production_rules[prod].each do |rule|
				rule.each { |r| queue.push r if term.include? r and not visited.include? r }
			end

			queue.uniq!
		end
		lambda_string += _lambda.join(" ")
		lambda_string.strip!
		return lambda_string
	end

	def print_firsts
		queue = [@goal]
		_lambda = []
		visited = []
		first_string = ""
		term = non_terminals


		until queue.empty?
			prod = queue.pop
			visited.push prod

			firsts = first_set prod
			first_string+= "First(#{prod})= #{firsts.join(" ")}\n"


			@production_rules[prod].each do |rule|
				rule.each { |r| queue.push r if term.include? r and not visited.include? r }
			end

			queue.uniq!
		end
		first_string += _lambda.join(" ")
		first_string.strip!
		return first_string
	end

	def print_follows
		queue = [@goal]
		_lambda = []
		visited = []
		follow_string = ""
		term = non_terminals


		until queue.empty?
			prod = queue.pop
			visited.push prod

			follow = follow_set prod
			#print "#{follow}"
			follow_string+= "Follow(#{prod})= #{follow[0].join(" ")}\n"


			@production_rules[prod].each do |rule|
				rule.each { |r| queue.push r if term.include? r and not visited.include? r }
			end

			queue.uniq!
		end
		follow_string += _lambda.join(" ")
		follow_string.strip!
		return follow_string
	end

	def print_predicts
		returnString = ""
		@production_rules.each_pair do |key, value|
			returnString+="Predict(#{key}) = #{predict_sets(key)}\n"
		end
		returnString+="Sets are disjoint: #{disjoint_test}\n"
		return returnString
	end

	# This is written using the general LR construction in the book
	# 	CompleteTable function, page 196
	# 	tryRuleInState, page 208
	# 	AssertEntry, page 196
	def completeTable(mach)
		filtered = {}
		table = mach.to_table

		# for each state in the machine
		mach.states.each_with_index do |s, index|
			# for each rule at a given state
			s.state.each do |lhs, rules|
				rules.each_with_index do |rule, offset|
					# tryRuleInState
					next unless rule.last == @marker

					follow_set(lhs).each do |sym|
						# assertEntry
						raise ShiftReductConflictError unless table[index][sym].nil?
						table[index][sym] = "#{lhs},#{offset}"
					end
				end
			end
		end
		
		# AssertEntry[StartState, Goalsymbol, accept_symbol]
		raise ShiftReductConflictError unless table[0][@goal].nil?
		table[0][@goal] = "accept"

		return table
	end
end

if __FILE__ ==  $0
	g = Grammar.new('tmp/biglanguage.cfg')

	# item_set = g.production_rules.each do |non, prods|
	#	prods.each { |rule| rule.unshift "." }
	# end

	item_set = {}
	item_set[g.goal] = g.production_rules[g.goal].each{ |rule| rule.unshift "." }

	puts "Item set is :#{item_set.inspect}"
	close = g.closure item_set
	puts "Closure is: #{close}"

	item_set["S"].first.each do |s|
		next if s == "."
		temp = g.goto(close, s)
		puts "Go to for symbol #{s} is :\n\t#{temp.inspect}"
	end
end
