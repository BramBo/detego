class ServiceProvider
  def initialize(container, service)
    @container = container
    @providee = service
  end

  def on(domain, service)
    @domain   = domain
    @service  = service
    self
  end
  
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
      service.invoke(method, args, block) unless service.nil?
    rescue => ex
      ContainerLogger.error "#{ex} for service: #{@providee.name}"
    ensure
      @domain = @service = nil
    end      
  end
end