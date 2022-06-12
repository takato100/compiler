class Semantics

  attr_reader :mem

  def initialize
    @stack = []
    @label = 0
  end

  def getoffset
    return @offset
  end

  def stack_length
    return @stack.length
  end

  def enterBlock()
    @stack.push(Hash.new)
    @offset = 3
    @mem = 3
    @maxdepth = 1
  end

  def leaveBlock()
    @offset -= @stack[-1].size
    @stack.pop
  end

  # dont init the offset
  def enterInnerBlock()
    # debug error
    if @stack.length < 1 then
      puts "error: not in init block"
      exit(1)
    end

    @stack.push(Hash.new)
  end

  # point: if two blocks were in a paralel rel, no need to duplicate memory
  # can use the previous(parallel) block's freed memory
  def leaveInnerBlock()
    # update memory size
    if @stack.length >= @maxdepth then
      @maxdepth = @stack.length
      mem = 3
      @stack.each{|s|
        mem += s.size
      }
      # needed when stack.length == @maxdepth
      if mem >= @mem then
        @mem = mem
      end
    end

    # update stack pointer
    @offset -= @stack[-1].size
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
    return nil
  end

  def makeLabel
    @label += 1
    return @label
  end

end



