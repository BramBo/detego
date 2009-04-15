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
  attr_accessor :interval
  attr_reader :message_stack
  exposed_methods :poll 
  
  def initialize 
     @message_stack = []  
     @poller     = FileSystemPoller.new(LOAD_PATH.gsub(/(^.+?[\/]+.+?)\/[^\/]+?\/[^\/]+?$/i, "\\1"), self)
     @interval ||= 120     
  end
  
  def start  
    begin  
    $provider.for($service[:domain].to_sym, $service[:name].to_sym).status = "Running.."
      loop do
        @poller.poll
        sleep(interval.to_i) # Sleep by default two minutes before polling again
      end
    rescue => e
      ContainerLogger.debug e, 1
      raise e
    end
  end
  
  def poll
    @message_stack = []
    @poller.poll
    return (@message_stack.size>0) ? @message_stack : "Nothing happend"
  end
end