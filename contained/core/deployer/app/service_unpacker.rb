class ServiceUnPacker
  def self.supported_file_type?(str)
    (str =~ /\.(zip|tar|gz)$/i)
  end

  def initialize(path, domain, service=nil)
    begin 
      @filename = (service) ? "#{path}/#{domain}/#{service}" : "#{path}/#{domain}"
      if send("un#{@filename.gsub(/^.+?\.([a-z]+)$/i, "\\1")}")
        system("rm -f #{@filename}")
      end
    rescue => e
      ContainerLogger.debug e, 1
      raise e
    end
      
    true
  end

  private 
   def unzip
    system("nice -n 5 unzip -qo #{@filename} -d #{@filename.gsub(/^(.+?)\..+?$/, "\\1")}") && $?.exitstatus == 0
   end  
  
   def untar
    system("nice -n 5 tar -C #{@filename.gsub(/^(.+?)\..+?$/, "\\1")} -zxvf #{@filename}") && $?.exitstatus == 0
   end  
    
   alias :ungz :unzip
   # def ungz
   #  system("nice -n 5 gunzip -f #{@filename}") && $?.exitstatus == 0
   # end
end