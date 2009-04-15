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
include_class('org.jruby.Ruby') {|pkg, name| "JJRuby" }

# @todo: fork to make processes asynch. Servers cant run synch. 
#         Probably best to do this using fork and drb to get the return value
class JJRuby
  def runScriptlet(code)  
    result = eval_scriptlet(%{
        begin
          #{code}
        rescue Exception => e
          "Execution error: " + e.message            
        rescue => e
          "Execution error: " + e.messagea
        end
      })
        
    if result.class.to_s.downcase =~ /string/ && !result.to_s.gsub!(/^execution.+?error\:/i, "").nil?
      ContainerLogger.warn "#{result}", 2
      raise Exception.new("#{@full_name} #{result}")
    end

    result
  end
end