 require '/.lexer'


class Parser
  def initializer(lexer)
    @lexer = lexer
    @token = lexer.lex() { |l|
      @lexime = l
    }
  end

  def parse()
    mE()
  end


  private

  def checktoken(f, expected)
    if @token == expected
      @token = @lexer.lex(){ |l|
        @lexime = l
      }
    else
      puts "syntax error (#{f}): #{expected} is expected"
      exit(1)
    end
  end

  def mF()
    case @token
    when :lpar
      checktoken("mF", :lpar)
    end
  end

  def mT()
  end

  def mE()
  end

