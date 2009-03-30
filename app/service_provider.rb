class ServiceProvider
  def initialize(container)
    @container = container
  end

  def on(domain, service)
    @domain   = domain
    @service  = service
    self
  end
  
  def method_missing(method, *args, &block)
    if @domain.nil?
      ContainerLogger.debug "No domain set in service provider call (#{method})!".console_yellow
      raise Exception.new("No domain set!") 
    end
    if @service.nil?
      ContainerLogger.debug "No service set in service provider call (#{method})!".console_yellow
      raise Exception.new("No domain set!") 
    end    
    service = @container.find(@domain).find(@service)      
    @domain = @service = nil
      
    service.invoke(method, args, block)
  end
end