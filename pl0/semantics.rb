class Semantics

  def initialize
    @stack = []
  end

  def getoffset
    return @offset
  end

  def enterBlock()
    @stack.push(Hash.new)
    @offset = 3
  end

  def leaveBlock()
    @stack.pop
  end

  def enterId(name)
    if @stack[-1][name] then
      puts "this id exists already(name = #{name})"
    else
      @stack[-1][name] = @offset
      @offset += 1
    end
  end

  def searchId(name)
    @stack[-1][name]
  end

  def searchAll(name)
    @stack.reverse_each{|e|
      if e[name] then
        return e[name]
      end
      }
      nil
    end

end



