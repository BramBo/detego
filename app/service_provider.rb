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


# Providers a way for the services to access the server through DRB 
# The provider is available in every service once it got started by the server
# $provider contains the DRB connection
# @todo: Change error reporting !
require "drb"

class ServiceProvider
  
  def initialize(container, service) #:nodoc:
    @container  = container
    @providee   = service
  end
  
  # Used for method_missing so that the provider may invoke the "missing method"
  # on the service class. 
  # 
  def on(domain, service)
    @domain   = domain
    @service  = service
    self
  end
  
      # Used to invoke methods on a service, from within a service
      #  used like: $provider.on(:domain_name, :service_name).set_status("New Status")
      #  this will simply invoke the method set_status on :service_name within :domain_name
      def method_missing(method, *args, &block)
        required_set?
        
        begin 
          service = @container.find(@domain).find(@service)        
          
          service.invoke(method, *args, &block) unless service.nil?
        rescue Exception => ex
          ContainerLogger.error "#{ex} for service: #{@providee.name}", 2
          raise Exception.new(ex)          
        rescue => ex
          ContainerLogger.error "#{ex} for service: #{@providee.name}", 2
          raise Exception.new(ex)
        ensure
          @domain = @service = nil
        end
        
      end
  
  #
  # Setter for instance variables @domain/@service
  def for(domain, service = nil)
    on(domain, service)
  end
  
  #
  # Get all the domains on the container callable like:  $provider.get_domains()
  def get_domains()
    begin
      return @container.find(:all).keys
    rescue => ex
      ContainerLogger.error "#{ex} for service: #{@providee.name}"
    ensure
      @domain = @service = nil
    end    
  end

    # Get all the services on the set domain callable like:  $provider.for(:domain_name).get_services()  
    def get_services()
      if @domain.nil?
        ContainerLogger.error "No domain set in service provider call (#{method})!".console_yellow
        raise Exception.new("No domain set!") 
      end
      
      begin 
        return @container.find(@domain).find(:all).keys
      rescue => ex
        ContainerLogger.error "#{ex} for service: #{@providee.name}"
        return ex
      ensure
        @domain = @service = nil
      end
      nil    
    end

      #
      # Get the service status string; No need to fetch the entire meta_data
      def status()
        required_set?

        begin 
          return @container.find(@domain).find(@service).status
        rescue => ex
          ContainerLogger.error "#{ex} for service: #{@providee.name}"
        ensure
          @domain = @service = nil
        end        
      end
    
      #
      # Get service meta-data {exposed_methods, exposed_variables }
      #  callable like:  $provider.for(:domain_name, :service_name).get_meta_data()   
      def get_meta_data()
        required_set?

        begin 
          data = @container.find(@domain).find(@service).meta_data      
          return {:service_methods => data.service_methods, :exposed_variables => data.exposed_variables, :readable_var_values => data.readable_var_values}
        rescue => ex
          ContainerLogger.error "#{ex} for service: #{@providee.name}"
        ensure
          @domain = @service = nil
        end    
      end
  
      #
      # Set a simple status string, so we can see how our service is doing
      def status=(str)
        begin
          service = @container.find(@domain).find(@service)
          service.status = str
        rescue => ex
          ContainerLogger.error "Error starting service #{@domain}::#{@service}!".console_yellow, 1
          raise Exception.new("Error starting service #{@domain}::#{@service}!")
        end
        "#{@service} status set: #{str}"
      end
  
      # Adds a service to the container
      #  Added for the deployservice and management interface
      def start_service()
        required_set?
        
        begin
          @container.find(@domain).find(@service).start()
        rescue Exception => ex
          ContainerLogger.error "Error starting service #{@domain}::#{@service}!".console_yellow, 1
          return "error;#{ex}"                    
        rescue => ex
          ContainerLogger.error "Error starting service #{@domain}::#{@service}!".console_yellow, 1
          return "error;Error starting service #{@domain}::#{@service}!"
        end
        "#{@service} started!"
      end
  
      # Stops a service
      #  Added for the deployservice and management interface
      def stop_service()
        required_set?
    
        begin
          @container.find(@domain).find(@service).shutdown()
          @container.find(@domain).find(@service).status
        rescue Exception => ex
          ContainerLogger.error "Error stopping service #{@domain}::#{@service}!".console_yellow, 1
          return "error;#{ex}"
        rescue => ex
          ContainerLogger.error "Error stopping service #{@domain}::#{@service}!".console_yellow, 1
          return "Error stopping service #{@domain}::#{@service}!"
        end
        "#{@service} stopped!"
      end
      
      # Stops a service
      #  Added for the deployservice and management interface      
      def restart_service()
        required_set?
    
        begin
          @container.find(@domain).find(@service).restart()
          
        rescue Exception => ex
          ContainerLogger.error "Error restarting service #{@domain}::#{@service}!".console_yellow, 1
          return "error;#{ex}"
        rescue => ex
          ContainerLogger.error "Error restarting service #{@domain}::#{@service}!".console_yellow, 1
          return "Error restarting service #{@domain}::#{@service}!"
        end
        "#{@service} restarted!"
      end
      
      # Limit the service by only the selected/set expose services
      #  if nothing is set it's available over all the expose services
      def expose_limit()
        required_set?

        begin
          return @container.find(@domain).find(@service).meta_data.limit_expose_to()
        rescue Exception => ex
          ContainerLogger.error "Error grabbing expose limit for service #{@domain}::#{@service}!".console_yellow, 1
          return "error;#{ex}"
        rescue => ex
          ContainerLogger.error "Error grabbing expose limit for service #{@domain}::#{@service}!".console_yellow, 1
          return "Error grabbing expose limit for service #{@domain}::#{@service}!"
        end
      end
      
  # Adds a domain (Basicly just create a dir.)
  #  Added for the management interface
  def add_domain(domain_name)
    begin 
      @container.add_domain(domain_name)
    rescue => ex
      ContainerLogger.error "Error adding domain #{domain_name}!", 1                  
      raise Exception.new("Error adding domain !")
    end
    true
  end

  # Adds a service to the container
  #  Added for the deployservice
  def add_service(domain_name, service_name)
    s= nil
    begin 
      s = @container.add_domain(domain_name).add_service(service_name)
      s.install()
    rescue => ex
      ContainerLogger.error "Error adding service #{domain_name}::#{service_name}!\n #{ex}", 1                  
      return "error;#{ex.message}"
    end
    
    begin     
        s.start
    rescue => ex
      ContainerLogger.error "Error starting service after install #{domain_name}::#{service_name}!\n #{ex}", 1                  
      return "error;#{ex.message}"
    end
    true
  end
  
  # Adds a service to the container
  #  Added for the deployservice
  def remove_service(domain_name, service_name)
    begin 
      @container.find(domain_name.to_sym).remove(service_name.to_sym)
    rescue => ex
      ContainerLogger.error "Error removing service #{domain_name}::#{service_name}!", 1
      raise Exception.new("Error removing service #{domain_name}::#{service_name}!")
    end

    true
  end
  
  # Adds a service to the container
  #  Added for the deployservice
  def remove_domain(domain_name)
    begin 
      domain = @container.find(domain_name.to_sym)
      @container.remove(domain_name.to_sym)
    rescue => ex
      ContainerLogger.error ex, 1            
      ContainerLogger.error "Error removing domain #{domain_name}!", 1                        
      raise Exception.new("Error removing domain #{domain_name}!")
    end

    true
  end    
  
  # Just a forwording message to ObservableBase
  # will add the service's ServiceManager to the specified group and event Observable(s)
  def subscribe(group, event = :all, filter = :none)      
    ObservableBase.instance().subscribe(@providee, group, event, filter)
  end

  # Just a forwording message to ObservableBase
  # will remove the service's ServiceManager from the specified group and event Observable(s)
  def unsubscribe(group, event = :all)
    ObservableBase.instance().unsubscribe(@providee, group, event)
  end
  
  # Just a forward method to ObservableBase, to enable e.g. $provider.const_get(:SERVICE)
  def const_get(const)
    ObservableBase.const_get(const)
  end


  def server_version()
    return DETEGO_VERSION
  end

  private 
    # Checks if the domain *and* the service are set
    # Most methods need these 2
    def required_set?()
      if @domain.nil?
        ContainerLogger.error "No domain set in service provider call (#{method})!"
        raise Exception.new("No domain set!") 
      end
      if @service.nil?
        ContainerLogger.error "No service set in service provider call (#{method})!"
        raise Exception.new("No domain set!") 
      end
    end
end