
# Class representing an NFA
# Works specifically with constructing an NFA with an AST
# generated from a regular expression's parse tree.
class Nfa
  attr_accessor :lambda_table, :transition_table, :accepting_states, :characters

  def initialize(ast)
    @lambda_table = []
    @transition_table = []
    @state_counter = 1
    @characters = Set.new
    @accepting_states = Set.new([1])
    process_node(ast, 0, 1)
    expand_lambda(@state_counter, @state_counter)
    expand_transition_table(@state_counter)
  end

  # Create a new NFA state and return its index
  def new_state()
    @state_counter += 1
    return @state_counter
  end

  # Helper method to expand the lambda transition table to the given size to allow
  # indexing to work properly.
  def expand_lambda(row, col)
    (row - @lambda_table.size + 1).times do |r|
      @lambda_table << []
    end

    @lambda_table.each.with_index do |table_row, row_index|
      (col - @lambda_table[row_index].size + 1).times do |c|
        table_row << 0
      end
    end
  end

  # Helper method to expand the character transition table to the given size to allow
  # indexing to work properly.
  def expand_transition_table(row)
    (row - @transition_table.size + 1).times do |r|
      @transition_table << {}
    end
  end

  # Set the lambda transition table at the given index to the given value
  def set_lambda(row, col, value)
    expand_lambda(row, col)
    @lambda_table[row][col] = value
  end

  # Set the character transition table at the given index to the given value
  def set_transition(row, col, value)
    expand_transition_table(row)

    # Values from the parse tree can have single quotes (for prettier output), so remove those
    col.gsub!("'", "")

    @characters.add(col)

    @transition_table[row][col] = value
  end

  # Delegate node processing to the proper function based on node contents
  def process_node(node, this, nxt)
    if node.value == "ALT"
      node_alt(node, this, nxt)
    elsif node.value == "SEQ"
      node_seq(node, this, nxt)
    elsif node.value == "*"
      node_kleene(node, this, nxt)
    elsif node.value == "lambda"
      leaf_lambda(node, this, nxt)
    else
      leaf_child(node, this, nxt)
    end
  end

  # Process a non-lambda leaf node
  def leaf_child(node, this, nxt)
    set_transition(this, node.value, nxt)
  end

  # Process a lambda leaf node
  def leaf_lambda(node, this, nxt)
    set_lambda(this, nxt, 1)
  end

  # Process a SEQ node
  def node_seq(node, this, nxt)
    a = this
    b = new_state()

    # Create a sequence of transitions between this and next, 
    # creating more states as needed
    node.children.each.with_index do |child, index|
      if index == node.children.size - 1
        b = nxt
      end

      process_node(child, a, b)

      a = b
      b = new_state()
    end
  end

  # Process an ALT node
  def node_alt(node, this, nxt)

    # Create an edge between this and next for each child
    node.children.each do |child|
      process_node(child, this, nxt)
    end
  end

  # Process a * node
  def node_kleene(node, this, nxt)
    set_lambda(this, nxt, 1)
    set_lambda(nxt, this, 1)

    process_node(node.children[0], this, nxt)
  end

  # Get all states connected to the given state by lambda transitions
  def get_lambda_transitions(state)
    transitions = []
    @lambda_table[state].each.with_index do |value, index|
      if value == 1
        transitions << index
      end
    end
    return transitions
  end

  # Get all states connected to the given state by transitions on the given character
  def get_transitions(state, char)
    transition = @transition_table[state][char]
    if transition
      return [transition]
    else
      return []
    end
  end

  # Put in human-readable format for output
  def to_s
    width = 3
    translations = {
      "\n" => "\\n",
      "\t" => "\\t",
      " "  => "\\s"
    }

    str = "Transition table:\n"

    str += "".ljust(width)
    @characters.each do |c|
      c = translations[c] if translations.has_key?(c)
      str += c.ljust(width)
    end

    str += "\n"

    @transition_table.each.with_index do |row, index|
      str += index.to_s.ljust(width)
      @characters.each do |c|
        str += row[c].to_s.ljust(width)
      end
      str += "\n"
    end

    str += "\nLambda table:\n"

    str += "".ljust(width)
    (0..@state_counter).each do |row|
      str += row.to_s.ljust(width)
    end

    str += "\n"

    (0..@state_counter).each.with_index do |row, index|
      str += index.to_s.ljust(width)
      (0..@state_counter).each do |col|
        str += @lambda_table[row][col].to_s.ljust(width)
      end
      str += "\n"
    end

    return str
  end

end
