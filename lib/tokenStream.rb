class TokenStream
	attr_reader :tokens
	def initialize path=nil
		raise ArgumentError, "Could not find file #{path}" if path.nil? or not File.exist?(path)

		@tokens = []
		File.readlines(path).each do |line|
			@tokens << Token.new(*line.strip.split)
		end

        # Add implicit end of stream token
        @tokens << Token.new("$")
	end

	def [] index
		return @tokens[index]
	end

	def reverse
		@tokens = @tokens.reverse
	end

	def first
		@tokens.first
	end

	def last
		@tokens.last
	end

	def to_s
		str = ""
		@tokens.each do |token|
			str += token.to_s + "\n"
		end
		return str
	end
end

class Token
	attr_reader :type, :value

	def initialize type=nil, val=nil
		@type = type
		@value = val
	end

	def to_s
		str = "#{@type}"
		if @value
			str += " (#{@value})"
		end
		return str
	end
end
