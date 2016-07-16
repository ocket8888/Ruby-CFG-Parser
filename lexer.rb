#!/usr/bin/env ruby

# adds lib directory to Gem path
$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))

%w{ grammar optparse regexTokenStream nfa dfa }.each { |gem| require gem }

regex_grammar = Grammar.new("lga_regex_grammar")

dfas = {}

File.open(ARGV[0], "r").each do |line|
  if line.size > 0
    name, regex = line.split
    stream = RegexTokenStream.new()
    stream.from_string(regex)
    tree = regex_grammar.makeTree(stream)
    tree.simplify!
    nfa = Nfa.new(tree)
    dfa = Dfa.new(nfa)

    dfas[name] = dfa
  end
end

dfas.each do |name, dfa|
  puts "Expression: #{name}", dfa
  puts "#" * 80 + "\n"
end
