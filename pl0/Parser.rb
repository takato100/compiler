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

  def errormsg(where, given, *expected_token)
    if expected_token == given || expected_token.include?(given) then
      gettoken()
    else
      ls = expected_token.join(" or ")
      puts "error at #{@lineno}::#{where} #{ls} is expected, though #{given} \"#{@lexime}\" is given"
      exit(1)
    end
  end

  def consume(where, expect)
    if @token == expect then
      gettoken()
      return true
    end
    return false
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
    errormsg("fdecls", @token, :ident)
    errormsg("fdecls", @token, :lpar)
    params()
    errormsg("fdecls", @token, :rpar)
    body()
  end

  def params()
    errormsg("params", @token, :ident)
    while @token == :comma
      gettoken()
      errormsg("params", @token, :ident)
    end
  end


  def main()
    errormsg("main", @token, :main)
    pl = body()
    return pl + "( CSP, 0, 2 )\n( OPR, 0, 0 )\n"
  end

  def body()
    pl_stmt = ""

    # semantics
    @sem_table.enterBlock()

    errormsg("body", @token, :lbra)
    pl_stmt += vardecls()
    pl_stmt += stmts()
    errormsg("body", @token, :rbra)

    # semantics
    @sem_table.leaveBlock()

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
      errormsg("vardecl", @token, :var)
      identlist()
      errormsg("vardecl", @token, :semi)
end

  def identlist()
    lexime = @lexime
    errormsg("identlist", @token, :ident)

    # add the id to semantics table
    @sem_table.enterId(lexime)

    while consume("identlist", :comma)
      lexime = @lexime
      errormsg("identlist", @token, :ident)

      # add the id to semantics table
      @sem_table.enterId(lexime)

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
      errormsg("stmt", @token, :write)
      pl = expression()
      errormsg("stmt", @token, :semi)
    when :writeln
      errormsg("stmt", @token, :writeln)
      errormsg("stmt", @token, :semi)
      pl = "( CSP, 0, 1 )\n"


    when :read
      errormsg("stmt", @token, :read)
      errormsg("stmt", @token, :ident)
      errormsg("stmt", @token, :semi)

    when :ident
      # sem
      ident_offset = @sem_table.searchId(@lexime)
      if ident_offset == nil then
        puts "semantic error: #{@lexime} not decleared"
      end

      errormsg("stmt", @token, :ident)
      errormsg("stmt", @token, :coleq)
      pl += expression()
      errormsg("stmt", @token, :semi)

      # semantics
      pl += "( STO, 0, #{ident_offset} )\n"

    when :if
      pl += ifstmt()
    when :while
      pl += whilestmt()
    when :lbra
      pl += body()
    when :return
      errormsg("stmt", @token, :return)
      expression()
      errormsg("stmt", @token, :semi)
    else
    errormsg("stmt", @token, :write, :writeln, :read, :ident, :if, :while, :lbra, :return)
    end
    return pl
  end

  def ifstmt()
    pl = ""

    # condition
    errormsg("if", @token, :if)
    pl += condition()

    # JPC
    else_label = @sem_table.makeLabel
    pl += "( JPC, 0, #{else_label} )\n"

    # stmt
    errormsg("then", @token, :then)
    pl += stmt()

    # jump to fin
    fin_label = @sem_table.makeLabel
    pl += "( JMP, 0, #{fin_label} )\n"

    # else part
    if @token == :else then
      gettoken()
      pl += "( LAB, 0, #{else_label} )\n" + stmt()
    end
    errormsg("ifstmt", @token, :endif)
    errormsg("ifstmt", @token, :semi)

    # if-end label
    pl += "( LAB, 0, #{fin_label} )\n"

    return pl
  end

  def whilestmt()
    errormsg("whilestmt", @token, :while)
    condition()
    errormsg("whilestmt", @token, :do)
    stmt()
  end

  def condition()
    pl = cexp()
    return pl
  end

  def cexp()
    pl = ""
    op = ""
    pl += expression()
    token = @token
    errormsg("cexp", @token, :eq)
    case token
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
    end
    pl += expression()
    return pl + op
  end

  def expression()
    op = ""
    pl = term()

    # maybe rewrite to conusme?
    while @token == :plus || @token == :minus
      op += pop()
      pl += term()
    end
    return pl + op
  end

  def pop()
    case @token
    when :plus
      op = 2
    when :minus
      op = 3
    end
    errormsg("po", @token, :plus, :minus)
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
    case @token
    when :mult
      op = "4"
    when :div
      op = "5"
    end
    errormsg("mop", @token, :mult, :div)
    return  "( OPR, 0, #{op} )\n"
  end


  def factor()
    pl = ""
    case @token
    when :number
      pl = "( LIT, 0, #{@lexime} )\n"
      errormsg("factor", @token, :number)
    when :lpar
      gettoken()
      expression()
      errormsg("factor", @token, :rpar)
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
        errormsg("factor", @token, :rpar)
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




