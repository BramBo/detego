require 'java'
require 'java_macros'
require 'fileutils'
require "service"

# Every Domain has it's own context/JRuby instance
class Domain
  attr_accessor :name
  
  def initialize(name, container)
    raise Exception.new("#{name} is not a valid domain name") unless valid_directory_name(name.to_s)
    
    @name       = name
    @services   = Hash.new
    @container  = container
    
    # Create the domain directory if not present
    FileUtils.mkdir_p("#{SERVICES_PATH}/#{@name}", :mode => 0755)
  end
    
  def add_service(name)
    raise Exception.new("#{name} is already taken on domain #{@name}") unless @services[name].nil? 
    serv = new_service(Service.new(name, self))
  end
    
  def find(service_name)
    return @services  if service_name == :all
    
    service = @services[service_name]
    return service    unless service.nil? 
    
    ContainerLogger.warn "Unexisting service called: #{@name}::#{service_name}", 1
    nil
  end
  
  private
    def new_service(service)
      @services[service.name]         = service
      
      # @todo: Expand with org.jruby.RubyInstanceConfig
      @services[service.name].runtime = JJRuby.newInstance()
      
      DRb.start_service "druby://127.0.0.1:#{service.port_in}", ServiceProvider.new(@container, @services[service.name])
      
      return @services[service.name]
    end
  
end