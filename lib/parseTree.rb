require 'ruby-graphviz'

class ParseTree
	attr_accessor :parent, :children, :value

	def initialize val=nil
		@parent = nil
		@children = []
		@value = val
	end

	def add_child val
		return false if val.nil?
		temp = (ParseTree.new val)
		temp.parent = self

		@children << temp
		return temp
	end

	def << val
		add_child val
	end

	def to_graphviz file=nil, opts={}
		g = GraphViz.new(:ParseTree)
		g.add_node(self.__id__.to_s).label = @value

		queue = @children.clone

		until queue.empty? do 
			child = queue.shift
			g.add_node(child.__id__.to_s).label = child.value == "lambda" ? "&lambda;" : child.value.to_s
			g.add_edge child.parent.__id__.to_s, child.__id__.to_s

			queue.push(child.children.clone)
			queue.flatten!
		end

		opts[:type] ||= :png
		g.output( opts[:type].to_sym => file ) unless file.nil?

		return g
	end

## run with dot like hellman 
	#$: dot -T png -o parse.png && open parse.png
	def to_file file
		out="graph Pt {\n  ordering=out;\n"
		out+="\"#{self}\" [label=\"#{@value}\" shape=box];\n"

		queue = @children.clone

		until queue.empty? do 
			child = queue.shift

			out+="\"#{child}\" [label=\"#{child.value}\"];\n"
			out+="\"#{child.parent}\" -- \"#{child}\";\n"

			queue.push(child.children.clone)
			queue.flatten!
		end

		out+= "\n}"
		open(file, 'w') do |f|
 			f.puts out
		end
		#File.write(file, out)
	end

    def deep_copy
        tree = ParseTree.new
        tree.value = @value
        tree.parent = @parent
        tree.children = []
        @children.each do |child|
            tree.children << child.deep_copy
            tree.children[-1].parent = tree
        end
        return tree
    end

    def simplify!
        @children.each do |child|
            child.simplify!
        end

        if @value == "NUCLEUS"
            simplify_nucleus!
        elsif @value == "ATOM"
            simplify_atom!
        elsif @value == "SEQLIST"
            simplify_seqlist!
        elsif @value == "SEQ"
            simplify_seq!
        elsif @value == "ALTLIST"
            simplify_altlist!
        elsif @value == "ALT"
            simplify_alt!
        elsif @value == "RE"
            simplify_re!

        end
    end

    def simplify_nucleus!
        if @children[0].value.type == "open"
            @value = @children[1].value
            @children = @children[1].children
            @children.each do |child|
                child.parent = self
            end
            return
        end

        if @children[1].value == "CHARRNG" and @children[1].children[0].value != "lambda"
            start = @children[0].value.value
            finish = @children[1].children[1].value.value
            
            @value = "ALT"
            @children = []

            Range.new(start, finish).each do |c|
                add_child("'#{c}'")
            end

        elsif @children[1].value == "CHARRNG"
            @value = "'#{@children[0].value.value}'"
            @children = []
        end

    end

    def simplify_atom!

        # If ATOMMOD is lambda
        if @children[1].children[0].value == 'lambda'

            # Replace children with NUCLEUS children
            @value = @children[0].value
            @children = @children[0].children
            @children.each do |child|
                child.parent = self
            end

        else

            # If ATOMMOD is kleene
            if @children[1].children[0].value.type == 'kleene'

                # Replace node with * node and remove ATOMMOD
                @value = "*"
                @children.pop

            # If ATOMMOD is plus
            elsif @children[1].children[0].value.type == 'plus'
                
                # Replace node with SEQ
                @value = "SEQ"

                # Replace ATOMMOD with *
                @children[1].value = "*"
                
                # Replace ATOMMOD's children with copy of NUCLEUS children
                @children[1].children[0] = @children[0].deep_copy
                @children[1].children[0].parent = @children[1]
            end
            
        end
    end

    def simplify_seqlist!

        # SEQLIST -> lambda rule
        if @children[0].value == 'lambda'

            # Remove lambda child
            @children = []

        # SEQLIST -> ATOM SEQLIST
        else

            # Append child SEQLIST's children to own children and remove child SEQLIST
            @children.concat(@children[1].children)
            @children.delete_at(1)
            @children.each do |child|
                child.parent = self
            end

        end
    end

    def simplify_seq!

        # SEQLIST -> ATOM SEQLIST
        if @children.size >= 2

            # Append child SEQLIST's children to own children and remove child SEQLIST
            @children.concat(@children[1].children)
            @children.delete_at(1)
            @children.each do |child|
                child.parent = self
            end
        end

        # Any case where only one child remains after previous step (can be lambda)
        if @children.size == 1

            # Replace self with child node
            @value = @children[0].value
            @children = @children[0].children
            @children.each do |child|
                child.parent = self
            end
        end
    end

    def simplify_altlist!

        # ALTLIST -> lambda
        if @children[0].value == 'lambda'

            # Remove lambda child
            @children = []

        # ALTLIST -> pipe SEQ ALTLIST
        else

            # Append child ALTLIST's children to own children
            @children.concat(@children[2].children)

            # Remove child pipe
            @children.delete_at(0)

            # Remove child ALTLIST
            @children.delete_at(1)

            # Re-parent children
            @children.each do |child|
                child.parent = self
            end
        end
    end

    def simplify_alt!

        # Append child ALTLIST's children to own children and remove child ALTLIST
        @children.concat(@children[1].children)
        @children.delete_at(1)
        @children.each do |child|
            child.parent = self
        end

        # If only one child remains after simplification
        if @children.size == 1

            # Replace self with only child
            @value = @children[0].value
            @children = @children[0].children
            @children.each do |child|
                child.parent = self
            end
        end
    end

    def simplify_re!

        # Replace self with first child
        @value = @children[0].value
        @children = @children[0].children
        @children.each do |child|
            child.parent = self
        end

    end
end
