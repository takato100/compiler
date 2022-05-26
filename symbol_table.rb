class STM

  Tint = :int
  Tstring = :string

  def initialize()
    @table = Hash.new()
  end


  def enterId(name, type)
    if @table[name]
      puts "#{name} is decleared  already"
      exit
    else
      @table[name] = type
    end
  end

  def searchId(name)
    @table[name]
  end

end
