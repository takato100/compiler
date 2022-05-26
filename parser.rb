#! /usr/bin/env ruby

require './lexer'
require './symbol_table'
 
class Parser
  def initialize(lexer)
    @lexer = lexer
    @symTable = STM.new()
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
        getAndCheckToken("mF", :rpar)
      when :num
        @lexime.to_i
        getAndCheckToken("mF", :num)
      when :id

        expectedType = @symTable.searchAll(@lexime)
        if expectedType == nil
          puts "error: #{@lexime} is not decleared (mF)"
          exit
        end

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

    def rhs(lhtype, name)
      case @token
      # Tint
      when :id, :num, :lpar
        if lhtype != STM::Tint
          puts "type error: lh(#{lhtype}, \"#{name}\") "+
            "rh(:int)"
          exit
        end
        mE()
      # string
      when  :lstring
        if lhtype != STM::Tstring
          puts "type error: lh(#{lhtype}, \"#{name}\") "+
            "rh(:string, \"#{@lexime}\")"
          exit
        end
        getAndCheckToken("rhs", :lstring)
      else
        errormsg("rhs", @token, :id, :num, :lpar, :lstring)
      end
    end

    def assign()
      case @token
      when :id
        lhtype = @symTable.searchAll(@lexime)
        lhname = @lexime
        if lhtype == nil
          puts "error : id(#{@lexime}) not decleared (rhs)"
          exit
        end
        getAndCheckToken("assign", :id)
        getAndCheckToken("assign", :eq)
        rhs(lhtype, lhname)
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
        statement()
      end
    end

    def decl()
      case @token
      when :int
        getAndCheckToken("decl", :int)
        lexime = @lexime
        getAndCheckToken("decl", :id)
        getAndCheckToken("decl", :semi)
        @symTable.enterId(lexime, STM::Tint)
      when :string
        getAndCheckToken("decl", :string)
        lexime = @lexime
        getAndCheckToken("decl", :id)
        getAndCheckToken("decl", :semi)
        @symTable.enterId(lexime, STM::Tstring)
      else
        errormsg("decl", @token, :int, :string)
      end

    end

    def declPart()
      decl()
      while @token == :int || @token == :string
        decl()
      end
    end

    def block()
      if @token != :lbrace
        errormsg("block", @token, :lbrace)
      else
        @symTable.enterBlock()
        getAndCheckToken("block", :lbrace)
        declPart()
        usePart()
        getAndCheckToken("block", :rbrace)
        @symTable.leaveBlock()
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
