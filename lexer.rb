#! /usr/bin/env ruby
#
class Lexer
  def initialize(f)
    @srcf = f
    @line = ""
    @lineno = 0
  end

  def lex()

    # delete spaces for the "empty?"
    if /\A\s+/ =~ @line
      @line = $'
    end

    while @line.empty? do
      @line = @srcf.gets
      if @line == nil
        return false
      end
      @line = @line.chomp
      @lineno += 1
    end

    # ignore the free begining space
    if /\A\s+/ =~ @line
      @line = $'
      @line = @line.chomp
    end



    case @line
    # \b = words border
    when /\Aint\b/
      yield($&, @lineno)
      token = :int
    when /\Astring\b/
      yield($&, @lineno)
      token = :string
    when /\Areal\b/
      yield($&, @lineno)
      token = :real
    when /\A\d+\.\d+/
      yield($&, @lineno)
      token = :rnum 
    when /\A\d+/
      yield($&, @lineno)
      token = :num
    when /\A=/
      yield($&, @lineno)
      token = :eq
    when /\A\+/
      yield($&, @lineno)
      token = :plus
    when /\A\*/
      yield($&, @lineno)
      token = :mult
    when /\A\(/
      yield($&, @lineno)
      token = :lpar
    when /\A\)/
      yield($&, @lineno)
      token = :rpar
    when /\A\{/
      yield($&, @lineno)
      token = :lbrace
    when /\A\}/
      yield($&, @lineno)
      token = :rbrace
    when /\A[a-zA-Z_]\w*/
      yield($&, @lineno)
      token = :id
    when /\A"\w*"/
      yield($&, @lineno)
      token = :lstring
    when /\A\;/
      yield($&, @lineno)
      token = :semi
    when /\A\n/
      yield($&, @lineno)
      token = :line
    end
    @line = $'
    return token
  end
end


