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
require 'java'
require 'java_macros'
require "service"
require "service_provider"

class Domain
  attr_accessor :name
  attr_reader   :container
  
  # Initialize a new domain
  #  make directories if needed
  def initialize(name, container)
    raise Exception.new("#{name} is not a valid domain name") unless valid_directory_name(name.to_s)
    
    @name       = name
    @services   = Hash.new
    @container  = container
    
    # Create the domain directory if not present
    FileUtils.mkdir_p("#{SERVICES_PATH}/#{@name}", :mode => 0755)
    
    ContainerLogger.debug "Domain added #{name}"
  end

  # Public method to add a Service
  #   new_services(Service.new) gets called
  def add_service(name)
    serv = @services[name] || new_service(Service.new(name, self))
    @services.sort{|a,b| "#{a[0]}"<=>"#{b[0]}"}
    serv
  end
    
  # :service_name || :all as paramater
  #   :all gives the entire collection of services on this domain
  #   :service_name will return a service or nil if none can be found
  def find(service_name)
    return @services if service_name == :all
    
    service = @services[service_name]
    return service    unless service.nil? 
    
    ContainerLogger.warn "Unexisting service called: #{@name}::#{service_name}", 1
    nil
  end
  
  # Remove a specific service, namely : s
  #  if s == nil All services will be removed!
  def remove(s=nil)
    if s == :all
      @services.each do |k, s|
        name = s.name
        s.shutdown() if s.started?
        s.uninstall
      end
      
      @services.clear
      FileUtils.rm_rf("#{SERVICES_PATH}/#{@name}")      
    else
      service = find(s)
      service.shutdown() if service.started?
      service.uninstall
      @services.delete(s)
      
      notify_observable_base(ObservableBase::SERVICE_REMOVED, {:domain => @name, :service => service.name})
    end
    
    true
  end
  
  private
    # A new service is created, set the needed properties
    #  Instantiate a new runtime
    #  Start a new DRB server so this service can access it's ServiceProvider
    def new_service(service)
      @services[service.name]         = service

      notify_observable_base(ObservableBase::SERVICE_ADDED, {:domain => @name, :service => service.name})
      return @services[service.name]
    end
    
    def notify_observable_base(event, details={})
      ObservableBase.instance().update(self, ObservableBase::DOMAIN, event, details)
    end
end