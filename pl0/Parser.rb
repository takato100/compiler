require "./lexer.rb"
require "./semantics.rb"


class Parser
  @lexime = ""

  # 自分の請け負ったトークンのみを処理する
  # 最後にgettoken()などいらない
  #


  def initialize(f)
    @lexer = Lexer.new(f)
    @sem_table = Semantics.new
    
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
    pl = main()
    return pl
  end

  def fdecls()
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
      pl = body()
    end
    return pl + "( CSP, 0, 2 )\n( OPR, 0, 0 )\n"
  end

  def body()
    pl_stmt = ""

    # semantics
    @sem_table.enterBlock()

    if @token != :lbra then
      errormsg("body", :lbra, @token)
      exit(1)
    else
      gettoken()
      pl_stmt += vardecls()
      pl_stmt += stmts()
      if @token != :rbra then
        errormsg("body", :rbra, @token)
        exit(1)
      end

      # semantics
      @sem_table.leaveBlock()

      gettoken()
    end

    return pl_stmt

  end

  def vardecls()
    while @token == :var
      vardecl()
    end
    symbol_amount = @sem_table.getoffset
    return "( INT, 0, #{symbol_amount} )\n"
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

    # add the id to semantics table
    @sem_table.enterId(@lexime)

    gettoken()
    while @token == :comma
      gettoken()
      if @token != :ident then
        errormsg("identlist", :ident, @token)
        exit(1)
      end

      # add the id to semantics table
      @sem_table.enterId(@lexime)

      gettoken()
    end
  end

  def stmts
    pl_stmt = ""
    while [:write, :writeln, :read, :ident, :if, :while, :lbra, :return].include?(@token)
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
      pl = "( CSP, 0, 1 )\n"

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

    when :ident
      # sem
      ident_offset = @sem_table.searchId(@lexime)
      if ident_offset == nil then
        puts "semantic error: #{@lexime} not decleared"
      end

      gettoken()
      if @token != :coleq then
        errormsg("stmt", :coleq, @token)
        exit(1)
      end
      gettoken()
      pl += expression()
      if @token != :semi then
        errormsg("stmt", :semi, @token)
      end

      # semantics
      pl += "( STO, 0, #{ident_offset} )\n"

      gettoken()
    when :if
      pl += ifstmt()
    when :while
      pl += whilestmt()
    when :lbra
      pl += body()
    when :return
      gettoken()
      expression()
      if @token != :semi
        errormsg("stmt", :semi, @token)
        exit(1)
      end
      gettoken()
    else
      errormsg("stmt", [:write, :writeln, :read, :ident, :if, :while, :lbra, :return], @token)
      exit(1)
    end
    return pl
  end

  def ifstmt()
    pl = ""
    if @token != :if
      errormsg("if", :if, @token)
      exit(1)
    else
      gettoken()
      pl += condition()
      # JPC
      else_label = @sem_table.makeLabel
      pl += "( JPC, 0, #{else_label} )\n"

      if @token != :then
        errormsg("then", :then, @token)
        exit(1)
      else
        gettoken()
        pl += stmt()

        # jump to fin
        fin_label = @sem_table.makeLabel
        pl += "( JMP, 0, #{fin_label} )\n"

        # else
        if @token == :else then
          gettoken()
          pl += "( LAB, 0, #{else_label} )\n" + stmt()
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
          # if fin label
          pl += "( LAB, 0, #{fin_label} )\n"
          gettoken()
        end
      end
    end
    return pl
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
    pl = cexp()
    return pl
  end

  def cexp()
    pl = ""
    op = ""
    pl += expression()
    case @token
    when :eq
      op += "( OPR, 0, 8 )\n"
    when :neq
      op += "( OPR, 0, 9 )\n"
    when :lt
      op += "( OPR, 0, 10 )\n"
    when :gt
      op += "( OPR, 0, 12 )\n"
    when :leq
      op += "( OPR, 0, 11 )\n"
    when :geq
      op += "( OPR, 0, 13 )\n"
    else
      errormsg("cexp", [:eq, :neq, :lt, :gt, :leq, :geq], @token)
      exit(1)
    end
    gettoken()
    pl += expression()
    return pl + op
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
      errormsg("pop", [:plus, :minus], @token)
      exit(1)
    end
    case @token
    when :plus
      op = 2
    when :minus
      op = 3
    end
    gettoken()
    return "( OPR, 0, #{op} )\n"
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
    return  "( OPR, 0, #{op} )\n"
  end


  def factor()
    pl = ""
    case @token
    when :number
      pl = "( LIT, 0, #{@lexime} )\n"
      gettoken()
    when :lpar
      gettoken()
      expression()
      if @token != :rpar then
        errormsg("factor", :rpar, @token)
        exit(1)
      end
      gettoken()
    when :ident
      # sem
      ident_offset = @sem_table.searchId(@lexime)
      if ident_offset == nil then
        puts "#{@lineno} sem erroor"
      end
      pl += "( LOD, 0, #{ident_offset} )\n"

      gettoken()
      if @token == :lpar then
        aparams()
        if @token != :rpar then
          errormsg("factor",:rpar, @token)
          exit(1)
        end
        gettoken()
      end
    end

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




