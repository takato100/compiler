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

  def essential(where, *expected)
    if expected == @token || expected.include?(@token) then
      gettoken()
    else
      ex_ls = expected.join(" or ")
      puts "error at #{@lineno}::#{where} #{ex_ls} is expected, though #{@token} \"#{@lexime}\" is given"
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
    essential("fdecls", :ident)
    essential("fdecls", :lpar)
    params()
    essential("fdecls", :rpar)
    body()
  end

  def params()
    essential("params", :ident)
    while @token == :comma
      gettoken()
      essential("params", :ident)
    end
  end


  def main()
    essential("main", :main)
    pl = body()
    return pl + "( CSP, 0, 2 )\n( OPR, 0, 0 )\n"
  end

  def body()
    pl_stmt = ""

    # semantics
    @sem_table.enterBlock()

    essential("body", :lbra)
    pl_stmt += vardecls()
    pl_stmt += stmts()
    essential("body", :rbra)

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
      essential("vardecl", :var)
      identlist()
      essential("vardecl", :semi)
end

  def identlist()
    lexime = @lexime
    essential("identlist", :ident)

    # add the id to semantics table
    @sem_table.enterId(lexime)

    while consume("identlist", :comma)
      lexime = @lexime
      essential("identlist", :ident)

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
      essential("stmt", :write)
      pl = expression()
      essential("stmt", :semi)
    when :writeln
      essential("stmt", :writeln)
      essential("stmt", :semi)
      pl = "( CSP, 0, 1 )\n"


    when :read
      essential("stmt", :read)
      essential("stmt", :ident)
      essential("stmt", :semi)

    when :ident
      # sem
      ident_offset = @sem_table.searchId(@lexime)
      if ident_offset == nil then
        puts "semantic error: #{@lexime} not decleared"
      end

      essential("stmt", :ident)
      essential("stmt", :coleq)
      pl += expression()
      essential("stmt", :semi)

      # semantics
      pl += "( STO, 0, #{ident_offset} )\n"

    when :if
      pl += ifstmt()
    when :while
      pl += whilestmt()
    when :lbra
      pl += body()
    when :return
      essential("stmt", :return)
      expression()
      essential("stmt", :semi)
    else
    essential("stmt", :return)
    end
    return pl
  end

  def ifstmt()
    pl = ""

    # condition
    essential("if", :if)
    pl += condition()

    # JPC
    else_label = @sem_table.makeLabel
    pl += "( JPC, 0, #{else_label} )\n"

    # stmt
    essential("then", :then)
    pl += stmt()

    # jump to fin
    fin_label = @sem_table.makeLabel
    pl += "( JMP, 0, #{fin_label} )\n"

    # else part
    if @token == :else then
      gettoken()
      pl += "( LAB, 0, #{else_label} )\n" + stmt()
    end
    essential("ifstmt", :endif)
    essential("ifstmt", :semi)

    # if-end label
    pl += "( LAB, 0, #{fin_label} )\n"

    return pl
  end

  def whilestmt()
    pl = ""
    essential("whilestmt", :while)

    # condition
    cond_label = @sem_talbe.makeLabel
    pl += "(LAB, 0, #{cond_label})"
    pl += condition()

    # exit jpc
    exit_label = @sem_table.makeLabel
    pl += "( JPC, 0, #{exit_label})"

    essential("whilestmt", :do)
    stmt()
    stmts()

    # jmp to condition
    pl += "(JMP, 0, #{cond_label})"

    # exit label
    pl += "( LAB, 0, #{exit_label})"
    return pl
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
    essential("cexp", :eq, :neq, :lt, :gt, :leq, :geq)
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
    essential("po", :plus, :minus)
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
    essential("mop", :mult, :div)
    return  "( OPR, 0, #{op} )\n"
  end


  def factor()
    pl = ""
    case @token
    when :number
      pl = "( LIT, 0, #{@lexime} )\n"
      essential("factor", :number)
    when :lpar
      essential("factor", :lpar)
      expression()
      essential("factor", :rpar)
    when :ident
      # sem
      ident_offset = @sem_table.searchId(@lexime)
      if ident_offset == nil then
        puts "#{@lineno} sem erroor"
      end
      pl += "( LOD, 0, #{ident_offset} )\n"

      gettoken()
      if @token == :lpar then
        essential("factor", :lpar)
        aparams()
        essential("factor", :rpar)
      end
    end

    return pl
  end

  def aparams()
    expression()
    while @token == :comma
      essential("aparams", :comma)
      expression()
    end
  end

end

parser = Parser.new($stdin)
pl = parser.parse
puts pl




