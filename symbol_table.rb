class STM

  Tint = :int
  Tstring = :string
  Treal = :real

  def initialize()
    # name(symbol's name) -> type(symbol type)
    @stack = []
  end


  def enterId(name, type)
    if @stack[-1][name]
      puts "#{name} is decleared  already"
      exit
    else
      @stack[-1][name] = type
    end
  end

  def searchId(name)
    # this is just a table
    # dont write error msg occured from the abscence of the symbol
    @stack[-1][name]
  end

  def searchAll(name)
    @stack.reverse_each{|h|
      if h[name]
        return h[name]
        exit
      end
    }
    nil
  end

  def enterBlock()
    @stack.push(Hash.new())
  end

  def leaveBlock()
    @stack.pop()
  end


end
