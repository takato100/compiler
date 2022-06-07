require "./lexer.rb"

class Parser
  @lexime = ""

  # 自分の請け負ったトークンのみを処理する
  # 最後にgettoken()などいらない
  #


  def initialize(f)
    @lexer = Lexer.new(f)
  end

  def parse
    @lineno = @lexer.lex(){|token, lexime|
      @token = token
      @lexime = lexime
    }
    pl = program()
    return pl
  end


  def gettoken()
    @lineno = @lexer.lex(){|token, lexime|
      @token = token
      @lexime = lexime
    }
  end

  def errormsg(where, *expected_token, given)
    ls = expected_token.join(" or ")
    puts "error at #{@lineno}::#{where} #{ls} is expected, though #{given} \"#{@lexime}\" is given"
  end

  def program()
    fdecls()
    pl_main = main()
    return pl_main
  end

  def fdecls()
    fdecl()
    while @token == :ident
      fdecl()
    end
  end


  def fdecl()
    if @token != :ident then
      errormsg("fdecl", :ident, @token)
      exit(1)
    end
    gettoken()
    if @token != :lpar then
      errormsg("fdecls", :lpar, @token)
      exit(1)
    end
    gettoken()
    params()
    if @token != :rpar then
      errormsg("fdecls", :rpar, @token)
      exit(1)
    end
    gettoken()
    body()
  end

  def params()
    if @token != :ident then
      errormsg("params", :ident, @token)
      exit(1)
    end
    gettoken()
    while @token == :comma
      gettoken()
      if @token != :ident then
        errormsg("params", :ident, @token)
        exit(1)
      end
      gettoken()
    end
  end


  def main()
    if @token != :main then
      errormsg("main", :main, @token)
      exit(1)
    else
      gettoken()
      pl_stmt = body()
    end
    pl_int = "( INT 0, 3 )"
    return pl_stmt + "( OPR, 0, 0 )"
end

  def body()
    if @token != :lbra then
      errormsg("body", :lbra, @token)
      exit(1)
    else
      gettoken()
      vardecls()
      pl_stmt = stmts()
      if @token != :rbra then
        errormsg("body", :rbra, @token)
        exit(1)
      end
      gettoken()
    end

    return pl_stmt

  end

  def vardecls()
    while @token == :var
      vardecl()
    end
  end

  def vardecl()
    if @token != :var then
      errormsg("vardecl", :var, @token)
      exit(1)
    else
      gettoken()
      identlist()
      if @token != :semi then
        errormsg("vardecl", :semi, @token)
        exit(1)
      end
      gettoken()
    end
  end

  def identlist()
    if @token != :ident then
      errormsg("identlist", :ident, @token)
      exit(1)
    end
    gettoken()
    while @token == :comma
      gettoken()
      if @token != :ident then
        errormsg("identlist", :ident, @token)
        exit(1)
      end
      gettoken()
    end
  end

  def stmts
    pl_stmt = ""
    while [:write, :writeln, :read, :if, :while, :lbra, :return].include?(@token)
      pl_stmt += stmt()
    end
    return pl_stmt
  end
    

  # one stmt, one pl-code
  def stmt()
    pl = ""
    case @token
    when :write
      gettoken()
      pl = expression()
      if @token != :semi
        errormsg("stmt", :semi, @token)
        exit(1)
      end
      gettoken()
    when :writeln
      gettoken()
      if @token != :semi
        errormsg("stmt", :semi, @token)
        exit(1)
      end
      pl = "( CSP, 0, 2 )\n"

      gettoken()
    when :read
      gettoken()
      if @token != :ident
        errormsg("stmt", :ident, @token)
        exit(1)
      end
      gettoken()
      if @token != :semi
        errormsg("stmt", :semi, @token)
        exit(1)
      end
      gettoken()
    gettoken()
    when :if
      ifstmt()
    when :while
      whilestmt()
    when :lbra
      body()
    when :return
      gettoken()
      expression()
      if @token != :semi
        errormsg("stmt", :semi, @token)
        exit(1)
      end
      gettoken()
    else
      errormsg("stmt", [:write, :writeln, :read, :if, :while, :lbra, :return], @token)
      exit(1)
    end
    return pl
  end

  def ifstmt()
    if @token != :if
      errormsg("if", :if, @token)
      exit(1)
    else
      gettoken()
      condition()
      if @token != :then
        errormsg("then", :then, @token)
        exit(1)
      else
        gettoken()
        stmt()
        if @token == :else then
          gettoken()
          stmt()
        end
        if @token != :endif then
          errormsg("ifstmt", :endif, @token)
          exit(1)
        else
          gettoken()
          if @token != :semi then
            errormsg("ifstmt", :semi, @token)
            exit(1)
          end
          gettoken()
        end
      end
    end
  end

  def whilestmt()
    if @token != :while
      errormsg("whilestmt", :while, @token)
      exit(1)
    else
      gettoken()
      condition()
      if @token != :do then
        errormsg("whilestmt", :do, @token)
        exit(1)
      else
        gettoken()
        stmt()
      end
    end
  end

  def condition()
    cexp()
  end

  def cexp()
    expression()
    case @token
    when :eq, :neq, :lt, :gt, :leq, :geq
      expression()
      gettoken()
    else
      errormsg("cexp", [:eq, :neq, :lt, :gt, :leq, :geq], @token)
      exit(1)
    end
  end

  def expression()
    op = ""
    pl = term()
    while @token == :plus || @token == :minus
      op += pop()
      pl += term()
    end
    return pl + op
  end

  def pop()
    if @token != :plus and @token != :minus then
      errormsg("pop", [:mult, :div], @token)
      exit(1)
    end
    case @token
    when :plus
      op = 2
    when :minus
      op = 3
    end
    gettoken()
    return "( OPR, 0, #{op})"
  end

  def term()
    op = ""
    pl = factor()
    while @token == :mult|| @token == :div
      op += mop()
      pl += factor()
    end
    return pl + op
  end

  def mop()
    if @token != :mult && @token != :div
      errormsg("mop", [:mult, :div], @token)
      exit(1)
    end
    case @token
    when :mult
      op = "4"
    when :div
      op = "5"
    end
    gettoken()
    return  "( OPR, 0, #{op})"
  end


  def factor()
    pl = ""
    case @token
    when :number
      pl = "( LIT, 0, #{@lexime} )"
    when :lpar
      gettoken()
      expression()
      if @token != :rpar then
        errormsg("factor", :rpar, @token)
        exit(1)
      end
    when :ident
      gettoken()
      if @token == :lpar then
        aparams()
        if @token != :rpar then
          errormsg("factor",:rpar, @token)
          exit(1)
        end
      end
    end
    gettoken()

    return pl
  end

  def aparams()
    expression()
    while @token == :comma
      expression()
    end
  end

end

parser = Parser.new($stdin)
pl = parser.parse
puts pl




