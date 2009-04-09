require 'java'
require 'java_macros'
require 'fileutils'
require "service"
require "service_provider"

class Domain
  attr_accessor :name
  
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
  end
    
  # :service_name || :all as paramater
  #   :all gives the entire collection of services on this domain
  #   :service_name will return a service or nil if none can be found
  def find(service_name)
    return @services  if service_name == :all
    
    service = @services[service_name]
    return service    unless service.nil? 
    
    ContainerLogger.warn "Unexisting service called: #{@name}::#{service_name}", 1
    nil
  end
  
  # Remove a specific service, namely : s
  #  if s == nil All services will be removed!
  def remove(s=nil)
    if s.nil?
      @services.each do |k, s|
        name = s.name
        s.stop() if s.started?
        s.uninstall
      end
      
      @services.clear
      Dir.unlink("#{SERVICES_PATH}/#{@name}")
    else
      service = find(s) 
      name    = service.name
      
      service.stop() if service.started?
      service.uninstall
      @services.delete(s)
    end
    
    true
  end
  
  private
    # A new service is created, set the needed properties
    #  Instantiate a new runtime
    #  Start a new DRB server so this service can access it's ServiceProvider
    def new_service(service)
      @services[service.name]         = service
      
      # @todo: Expand with org.jruby.RubyInstanceConfig
      @services[service.name].runtime = JJRuby.newInstance()
      
      DRb.start_service "druby://127.0.0.1:#{service.port_in}", ServiceProvider.new(@container, @services[service.name])
      
      return @services[service.name]
    end
end