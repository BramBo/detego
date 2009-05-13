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
class ServiceManager
  attr_accessor :port, :running_on

  def initialize
     @srv         = nil
     @port        = instance_variable_get("@port").to_i < 1024 ? 5055 : instance_Variable_get("@port")
     @running_on  = instance_variable_get("@running_on") ? instance_variable_get("@running_on") :  Socket.getaddrinfo(Socket.gethostname(), nil)[0][2]
  end

  def start
    self.status = "Running"
    @srv = RESTListener.new(@port, @running_on).start()
  end
  
  def shutdown()
    @srv.stop
  end
end