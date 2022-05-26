#! /usr/bin/env ruby

require './lexer'
 
class Parser
  def initialize(lexer)
    @lexer = lexer
    @lineno = 0
    # token type
    @token = lexer.lex() { |l, no|
      # token symbol
      @lexime = l
      @lineno = no
    }
  end

    def errormsg(rulename, token, *expected)
      exs = expected.join(" or ")
      puts "syntax error (no#{@lineno} rule: #{rulename}, token: #{@lexime}\(#{token}\)) : #{exs}  is expected"
    end

    def getAndCheckToken(rulename, expected)
      # check the equality of holding token and expected
      # get next token
      case @token
      when expected
        @token = @lexer.lex(){ |l, no|
          @lexime = l
          @lineno = no
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
      when :id, :num, :lpar
        mE()
      when  :lstring
        getAndCheckToken("rhs", :lstring)
      else
        errormsg("rhs", @token, :id, :num, :lpar, :lstring)
      end
    end

    def assign()
      case @token
      when :id
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
      while @token == :id || @token == :lbrace
        statement()
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
      while @token == :int || @token == :string
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
end



lexer = Lexer.new($stdin)
parser = Parser.new(lexer)
parser.parse
