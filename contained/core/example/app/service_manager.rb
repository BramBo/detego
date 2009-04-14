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


# The communication layer between this service and the server
class ServiceManager
  attr_accessor :hallo, :hoi
  attr_reader   :read_only
  attr_writer   :write_only  
  exposed_methods :say_hello, :set_status, :get_status, :sleep_test
  
  # Gets run by the server when start() is invoked on it. This will happen right after the installation, or can be invoked through the management interface
  def initialize
    @hallo      = "Hello"
    @hoi        = "Hey"
    @write_only = "NOT READABLE"
    @read_only  = "READ ONLY"
  end

  # Example function
  def say_hello
    return "hello from hello.rb in #{$service[:full_name]} #{str} Status: #{$state}"
  end

  # Another example function. See the management interface on port 5005
  def set_status(str)
    $state = str
  end
  
  #.....
  def get_status
    return "#{$service[:full_name]} status: #{$state}"
  end
  
  # This method should always be present in the service manager, this can be empty but the server will invoke this to start the service
  def start
     $provider.for($service[:domain].to_sym, $service[:name].to_sym).status= "Started"     
  end
  
  # Another example, just here to show off some nice js ^^
  def sleep_test
    sleep(10)
    "slept for 10 sec!"
  end
end