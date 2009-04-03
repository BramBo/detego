class ServiceUnPacker
  def initialize()
    
  end
  
  def unpack()
    
  end
  
  private 
   def gunzip(filename)
    command = "nice -n 5 gunzip --force #{filename}"
    success = system(command)
    
    return success && $?.exitstatus == 0
   end
  
end