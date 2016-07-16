require "tokenStream"

class RegexTokenStream < TokenStream
	CTRL_SYMBOLS = {
		"-" => "dash",
		"(" => "open",
		")" => "close",
		"|" => "pipe",
		"*" => "kleene",
		"+" => "plus"
	}

  ESCAPE_SEQUENCES = {
    "s" => " ",
    "t" => "\t",
    "n" => "\n"
  }

	def initialize path=nil
    return if path.nil?
		raise ArgumentError, "File #{path} not found" if not File.exist?(path)

		@tokens = []
		File.readlines(path).each do |line|
			@tokens += parse line
		end

		@tokens << Token.new("$")
	end

  def from_string(str)
		@tokens = []
    @tokens += parse str
		@tokens << Token.new("$")
  end

	def parse str
		raise ArgumentError, "Expected a string to parse. Instead received: #{str}" unless str.is_a? String

		force_char = false
		tokens = []

		str.split('').each do |c|
      if c == "\n"
        next
      end

			if c == '\\' and not force_char
				force_char = true
				next
			end

      if force_char and ESCAPE_SEQUENCES.has_key?(c)
        tokens << Token.new("char", ESCAPE_SEQUENCES[c])
			elsif force_char or not CTRL_SYMBOLS.has_key?(c)
        tokens << Token.new("char", c)
			else
				tokens << Token.new(CTRL_SYMBOLS[c])
			end

			force_char = false
		end

		return tokens
	end
end
