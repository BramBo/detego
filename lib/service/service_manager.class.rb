# Copyright (c) 2009 Bram Wijnands<brambomail@gmail.com>
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


#   Default implementation of the Service codebase' ServiceManager
class ServiceManager
  # DSL-method
  # Creates a array of methods to be exposed to the container.
  #   (The ServiceMetaData picks up this method)
  # The method takes a symbol or array of symbols
  def self.exposed_methods(*meths)
    define_method("all_methods") { [*meths] }
  end

  # DSL-method
  # Create a Hash for the ServiceMetaData
  # A methods may be described by parameters as follows:
  #  :method_name, "Parameter descr. I", "Parameter descr. II",..
  def self.has_parameters(meth, *params)
    (@@p ||= Hash.new)[meth.to_s] = params.to_a
  end

  # DSL-method
  # Creates an Array to limit the services this services gets exposed over
  #  f.e. limit_expose_to(:drb) will have this service only available over proxies::drb
  def self.limit_expose_to(pr = [])
    @@l = [*pr] unless pr.nil?
  end
  
  #+----------------------
  #| Overrideable methods
  #+----------------------
  # Method gets invoked after a service is initialized and gets started
  #  default impl. only set a status string
  def start()
    self.status="started" 
  end

  # "Macro" to set the status of this service on the container
  def status=(str)     
    $provider.for($service[:domain].to_sym, $service[:name].to_sym.to_sym).status = str
  end

  # "Macro" to Get the status of this service on the container  
  def status
    $provider.for($service[:domain].to_sym, $service[:name].to_sym.to_sym).status
  end
  
  # update/notify Observer-pattern method
  # When the service subscribes to any event-hook this methods NEEDS to be overwritten
  def update(group, event, params={})
    ServiceLogger.warn("Subscribed but default update implementation not overwritten!")
  end

  #+----------------------
  #| Meta-data gatherers 
  #+----------------------
  def all_parameter_methods;  @@p ||= Hash.new;   end    
  def limits;                 @@l ||= [];         end
  def all_methods;            [];                 end    
end  
