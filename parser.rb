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
        t1 = mE()
        getAndCheckToken("mF", :rpar)
      when :num
        @lexime.to_i
        getAndCheckToken("mF", :num)
        t1 = STM::Tint
      when :rnum
        @lexime.to_f
        getAndCheckToken("mF", :rnum)
        t1 = STM::Treal
      when :id

        expectedType = @symTable.searchAll(@lexime)
        if expectedType == nil
          puts "error: #{@lexime} is not decleared (mF)"
          exit
        elsif expectedType != STM::Treal && expectedType != STM::Tint
          puts "error: #{@lexime} needs to be decleared as real or in"
          exit
        else
          t1 = expectedType
        end

        getAndCheckToken("mF", :id)
      else
        errormsg("mF", @token, :lpar, :rpar, :num, :id, :rnum)
      end
      return t1
    end


    def mT()
      t1 = mF()
      while @token == :mult do
        getAndCheckToken("mT", :mult)
        t2 = mF()
        if t1 == STM::Tint && t2 == STM::Tint
          t1 = STM::Tint
        else
          t1 = STM::Treal
        end
      end
      return t1
    end

    def mE()
      t1 = mT()
      while @token == :plus do
        getAndCheckToken("mE", :plus)
        t2 = mT()
        if t1 == STM::Tint && t2 == STM::Tint
          t1 = STM::Tint
        else
          t1 = STM::Treal
        end
      end
      return t1
    end

    def rhs(lhtype, name)
      case @token
      # number(int or real)
      when :id, :num, :lpar, :rnum
        if lhtype != STM::Treal && lhtype != STM::Tint
          puts "type error: no#{@lineno}lh(#{lhtype}, \"#{name}\") "+
            "rh(:real or :int)"+
            "should be a evaluable expression"
          exit
        end
        t1 = mE()
        if t1 == STM::Treal && lhtype == STM::Tint
          puts "type error: no#{@lineno} lh(#{lhtype}, \"#{name}\") "+
            "rh(:real)"
          exit
        elsif t1 == STM::Tint && lhtype == STM::Treal
          puts "type error: no#{@lineno} lh(#{lhtype}, \"#{name}\") "+
            "rh(:int)"
          exit
        end

      # string
      when  :lstring
        if lhtype != STM::Tstring
          puts "type error: no#{@lineno} lh(#{lhtype}, \"#{name}\") "+
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
      when :real
        getAndCheckToken("decl", :real)
        lexime = @lexime
        getAndCheckToken("decl", :id)
        getAndCheckToken("decl", :semi)
        @symTable.enterId(lexime, STM::Treal)
      else
        errormsg("decl", @token, :int, :string, :real)
      end

    end

    def declPart()
      decl()
      while @token == :int || @token == :string || @token == :real
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
