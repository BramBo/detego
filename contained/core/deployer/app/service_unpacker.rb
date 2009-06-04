# Copyright (c) 2009 Bram Wijnands
#                                                                     
# Permission is hereby granted, free of charge, to any person         
# obtaining a copy of this software and associated documentation      
# files (the "Software"), to deal in the Software without             
# restriction, including without limitation the rights to use,        
# copy, modify, merge, publish, distribute, sublicense, and/or sell   
# copies of the Software, and to permit persons to whom the           
# Software is furnished to do so, subject to the following      
# conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

# unarchive a given file
class ServiceUnPacker
  def self.supported_file_types
    "(zip|tar|gz)"
  end
  
  def self.supported_file_type?(str)
    (str =~ /\.#{self.supported_file_types}$/i)
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
      
    "Unpacked #{@filename.gsub(/^.+?\.([a-z]+)$/i, "\\1").to_s} succesfully for #{domain.to_s}"
  end

  private 
   def unzip
    system("nice -n 5 unzip -qo #{@filename} -d #{@filename.gsub(/^(.+?)\..+?$/, "\\1")}") && $?.exitstatus == 0
   end  
  
   def untar
    system("nice -n 5 tar -C #{@filename.gsub(/^(.+?)\..+?$/, "\\1")} -zxvf #{@filename}") && $?.exitstatus == 0
   end  
    
   alias :ungz :untar
   # def ungz
   #  system("nice -n 5 gunzip -f #{@filename}") && $?.exitstatus == 0
   # end
end