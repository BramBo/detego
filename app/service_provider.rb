# Providers a way for the services to access the server through DRB 
# The provider is available in every service once it got started by the server
# $provider contains the DRB connection
#
class ServiceProvider
  def initialize(container, service) #:nodoc:
    @container = container
    @providee = service
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
        rescue => ex
          ContainerLogger.error "#{ex} for service: #{@providee.name}", 2, 2, 2
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
      domains = [] 
      @container.find(:all).each do |k,v|
        domains << k
      end
      return domains
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
        names = []
        @container.find(@domain).find(:all).each {|k,v| names << k }
        return names
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
      
          return {:service_methods => data.service_methods, :exposed_variables => data.exposed_variables}
        rescue => ex
          ContainerLogger.error "#{ex} for service: #{@providee.name}"
        ensure
          @domain = @service = nil
        end    
      end
  
      # Adds a service to the container
      #  Added for the deployservice and management interface
      def start_service()
        required_set?
    
        begin
          @container.find(@domain).find(@service).start()
        rescue => ex
          ContainerLogger.error "Error starting service #{domain_name}::#{service_name}!".console_yellow, 1
          raise Exception.new("Error starting service #{domain_name}::#{service_name}!")
        end
        true
      end
  
      # Stops a service
      #  Added for the deployservice and management interface
      def stop_service()
        required_set?
    
        begin
          @container.find(@domain).find(@service).stop()
        rescue => ex
          ContainerLogger.error "Error starting service #{domain_name}::#{service_name}!".console_yellow, 1
          raise Exception.new("Error starting service #{domain_name}::#{service_name}!")
        end
        true
      end
      
  # Adds a service to the container
  #  Added for the deployservice
  def add_service(domain_name, service_name)
    begin 
      s = @container.add_domain(domain_name).add_service(service_name).install()
      s.start
    rescue => ex
      ContainerLogger.error "Error adding service #{domain_name}::#{service_name}!", 1                  
      raise Exception.new("Error adding service #{domain_name}::#{service_name}!")
    end

    true
  end
  
  # Adds a service to the container
  #  Added for the deployservice
  def remove_service(domain_name, service_name)
    begin 
      serv = @container.find(domain_name).find(service_name)
      serv.shutdown()
      serv.remove(service_name)
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
      domain = @container.find(domain_name)
      
      domain.find(:all).each do |n, s|
        s.shutdown()
        s.remove(service_name)
      end
      
      domain.remove(domain_name)
    rescue => ex
      ContainerLogger.error ex, 1                        
      ContainerLogger.error "Error removing domain #{domain_name}!", 1                        
      raise Exception.new("Error removing domain #{domain_name}!")
    end

    true
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