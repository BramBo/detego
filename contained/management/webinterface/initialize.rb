# Copyright (c) 2009 Bram Wijnands<bram@kabisa.nl>
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
$interface_version = "0.4.10"

class ServiceManager
  attr_accessor :port  

  def start()
    # this doesnt take an int as a port nr ?!
    ARGV << "-p"; ARGV << (@port = ((@port.to_i||5050)>1024) ? @port : 5050).to_s

    # Mongrel needs to be started in the project root dir
    Dir.chdir(LOAD_PATH) if CONTAINER_PATH == Dir.getwd

    require 'config/boot'        
    Thread.new do
      self.status= "Running.."
    end  
    require 'commands/server'
  end
end