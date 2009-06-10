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

require "yaml"
# The communication layer between this service and the server
class ServiceManager
  attr_accessor :hello
  attr_reader   :read_only
  attr_writer   :write_only  
  exposed_methods :say_hello, :set_status, :get_status, :sleep_test, :get_random_array, :get_rand_dimension_hash, :concat
  limit_expose_to :drb
  
  # Gets run by the server when start() is invoked on it. This will happen right after the installation, or can be invoked through the management interface
  def initialize
    @hello      = "Hello world!"
    @invisible  = "Yarrr..."
    @write_only = "For your eyes only"
    @read_only  = "Can't be overwritten"
    
    # Pretty stupid but; Subscribe to self
    $provider.subscribe($provider.const_get(:SERVICE), :all)
  end

  # Example function
  def say_hello
    return "hello from #{$service[:full_name]}. Current status: #{$state}"
  end

  # Another example function. See the management interface on port 5050
  has_parameters(:set_status, "str")
  def set_status(str)
    self.status=(str)
  end
  
  #.....
  def get_status
    puts "status"    
    self.status="started statussing"
    return "#{$service[:full_name]} status: #{status}"
  end
  
  # Proxy test  
  def get_random_array
    (rand(5)..(rand(10)+5)).to_a
  end  

  # Proxy test  
  def get_rand_dimension_hash
    dimensions      = rand(5)+2
    dimension_size  = rand(5)+1    
    h = { :name     => "#{dimensions} Dimensions Hash"}
    
    dimension_size.times do |i|
      dimensions.times do |j|
        instance_eval(%{h#{"[:dimension]"*j} = {:name => "#{j}th dimension"}})
      end
    end
    h
  end
  
  # Javascript test (Ajax get, shouldn't raise a timeout and it should be visual that the request is processing)
  def sleep_test
    sleep(10)
    "slept for 10 sec!"
  end
  
  # Lots of params
  has_parameters(:concat, "conc_a", "conc_b", "conc_c", "conc_d", "conc_e")
  def concat(a,b,c,d,e)
    "#{e}_#{d}_#{c}_#{b}_#{a}"
  end
  
  def update(group, event, params)
    ServiceLogger.debug "Updating !:: #{group} #{event}".console_blue
    params.each do |k,v|
      ServiceLogger.debug  "[ #{k} |=> #{v} ]".console_purple
    end
    @read_only = "#{group}, #{event}, #{params}"
  end
end