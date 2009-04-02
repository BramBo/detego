class ServiceProvider
  def initialize(container, service)
    @container = container
    @providee = service
  end

  #
  # Simple instance variable setter
  def on(domain, service)
    @domain   = domain
    @service  = service
    self
  end
  
  # 
  # invoke `method` on @domain::@service
  def method_missing(method, *args, &block)
    if @domain.nil?
      ContainerLogger.error "No domain set in service provider call (#{method})!".console_yellow
      raise Exception.new("No domain set!") 
    end
    if @service.nil?
      ContainerLogger.error "No service set in service provider call (#{method})!".console_yellow
      raise Exception.new("No domain set!") 
    end

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
      return @container.find(:all)
    rescue => ex
      ContainerLogger.error "#{ex} for service: #{@providee.name}"
    ensure
      @domain = @service = nil
    end    
  end

  # Get all the domains on the container callable like:  $provider.for(:domain_name).get_services()  
  def get_services()
    if @domain.nil?
      ContainerLogger.error "No domain set in service provider call (#{method})!".console_yellow
      raise Exception.new("No domain set!") 
    end
      
    begin 
      return @container.find(@domain).find(:all)
    rescue => ex
      ContainerLogger.error "#{ex} for service: #{@providee.name}"
    ensure
      @domain = @service = nil
    end    
  end

  #
  # Get service meta-data {exposed_methods, exposed_variables }
  # callable like:  $provider.for(:domain_name, :service_name).get_meta_data()  
  def get_meta_data()
    if @domain.nil?
      ContainerLogger.error "No domain set in service provider call (#{method})!".console_yellow
      raise Exception.new("No domain set!") 
    end
    if @service.nil?
      ContainerLogger.error "No service set in service provider call (#{method})!".console_yellow
      raise Exception.new("No domain set!") 
    end

    begin 
      data = @container.find(@domain).find(@service).meta_data
      
      return {:exposed_methods => data.exposed_methods, :exposed_variables => data.exposed_variables}
    rescue => ex
      ContainerLogger.error "#{ex} for service: #{@providee.name}"
    ensure
      @domain = @service = nil
    end    
  end
end