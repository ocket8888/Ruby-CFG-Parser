
# Class representing a DFA
# Initialized with an NFA
class Dfa

  def initialize(nfa)
    l = []

    @nfa = nfa
    @table = {}
    @accepting = Set.new

    i = 0

    a = nfa.accepting_states
    b = follow_lambda(Set.new([i]))
    if a.intersect?(b)
      @accepting.add(b)
    end
    @table[b] = {}
    l.push(b)

    while l.size > 0 do
      s = l.pop()
      @nfa.characters.each do |c|
        r = follow_lambda(follow_char(s, c))

        @table[s][c] = r

        if r.size > 0 and not @table.has_key?(r)
          @table[r] = {}
  
          if a.intersect?(r)
            @accepting.add(r)
          end

          l.push(r)
        end

      end
    end

    @aliases = {}
    @reverse_aliases = {}
    index = 0
    @table.each do |key, value|
      @aliases[key] = index
      @reverse_aliases[index] = key
      index += 1
    end
  end

  def follow_lambda(s)
    l = []

    s.each do |t|
      l.push(t)
    end

    while l.size > 0 do
      t = l.pop
      @nfa.get_lambda_transitions(t).each do |q|
        if not s.include?(q)
          s.add(q)
          l.push(q)
        end
      end
    end
    return s
  end

  def follow_char(s, c)
    f = Set.new()

    s.each do |t|
      # puts "T: #{t}, C: #{c}, #{@nfa.get_transitions(t, c)}"
      @nfa.get_transitions(t, c).each do |q|
        f.add(q)
      end
    end

    return f
  end

  def to_s
    translations = {
      "\n" => "\\n",
      "\t" => "\\t",
      " "  => "\\s"
    }
    width = 3
    str = "DFA:\n"

    str += "".ljust(width)

    characters = @nfa.characters.to_a

    characters.each do |char|
      char = translations[char] if translations.has_key?(char)
      str += char.to_s.ljust(width)
    end
    str += "\n"

    @table.each do |state, transitions|
      str += @aliases[state].to_s.ljust(width)

      characters.each do |char|
        state = transitions[char]
        state = @aliases[state]
        str += state.to_s.ljust(width)
      end

      str += "\n"
    end

    str += "\nAccepting states:\n"
    @accepting.each do |state|
      str += @aliases[state].to_s
      str += "\n"
    end


    return str
  end

end
