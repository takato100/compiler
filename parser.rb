 require '/.lexer'


class Parser
  def initializer(lexer)
    @lexer = lexer
    # token type
    @token = lexer.lex() { |l|
      # token symbol
      @lexime = l
    }
  end

  def parse()
    mE()
  end


  private


    def errormsg(rulename, token, expected*)
      exs = expected.join(" or ")
      puts "syntax error (#{rule}, #{token}) : #{exs}  is expected"
    end

    def getAndCheckToken(rulename, expected)
      # check the equality of holding token and expected
      # get next token
      if @token == expected
        @token = @lexer.lex(){ |l|
          @lexime = l
        }
      else
        errormsg(rulename, @token, expected)
        exit(1)
      end
    end


    def mF()
      case @token
      when :lpar
        getAndCheckToken("mF", :lpar)
        mE()
        getAndCheckToken("f", :rpar)
      when :num
        @lexime.to_i
        getAndCheckToken("mF", :num)
      when :id
        getAndCheckToken("mF", :id)
      else
        errormsg("mF", @token, :lpar, :rpar, :num, :id)
      end
    end


    def mT()
      mF()
      while @token == :mult do
        getAndCheckToken("mT", :mult)
        mF()
      end
    end

    def mE()
      mT()
      while @token == :plus do
        getAndCheckToken("mE", :plus)
        mT()
      end
    end

    def rhs()
      case @token
      when  :id, :num, :lpar
        mE()
        getAndCheckToken("rhs", :semi)
      when  :lstring
        getAndCheckToken("rhs", :lstring)
      else
        errormsg("rhs", @token, :id, :num, :lpar, :lstring)
      end
    end

    def assign()
      case @token :id
        getAndCheckToken("assign", :id)
        getAndCheckToken("assign", :eq)
        rhs()
        getAndCheckToken("assign", :semi)
      else
        errormsg("assign", :id)
      end
    end

    def statement()
      case @token
      when :id
        assign()
      when :lbrace
        block()
      else
        errormsg("statement", @token, :id, :lbrace)
      end
    end

    def usePart()
      statement()
      while @token == :id || @token == :lbrace
        st()
      end
    end

    def decl()
      case @token
      when :int
        getAndCheckToken("decl", :int)
      when :string
        getAndCheckToken("decl", :string)
      else
        errormsg("decl", @token, :int, :string)
      end
      getAndCheckToken("decl", :id)
      getAndCheckToken("decl", :semi)
    end

    def declPart()
      decl()
      while @token == :id || @token == :string
        decl()
      end
    end

    def block()
      if @token != :lbrace
        errormsg("block", @token, :lbrace)
      else
        getAndCheckToken("block", :lbrace)
        declPart()
        usePart()
        getAndCheckToken("block", :rbrace)
      end
    end

    def program()
      block()
    end
    
    def parse()
      program()
    end



lexer = Lexer.new($stdin)
parser = Parser.new(lexer)
puts purser.parse
