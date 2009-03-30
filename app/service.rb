require "service_meta_data"

class Service
  attr_reader :started, :path, :full_name, :meta_data, :port
  attr_accessor :name, :runtime
    
  def initialize(name, domain)
    @name       = name
    @port       = ($port_start+=1)
    @booted     = false
    @domain     = domain
    @full_name  = "#{domain.name}::#{name}"
    @path       = "#{SERVICES_PATH}/#{domain.name}/#{name}"
    
    # Create the domain directory if not present
    FileUtils.mkdir_p(@path, :mode => 0755)
    
    # And finally set the meta-data for the service
    @meta_data  = ServiceMetaData.new(self)
  end

  # Start/boot the service 
  # 
  def start
    raise Exception.new("No Runtime defined for: #{@full_name}") if @runtime.nil?

    # Boot it
    @runtime.runScriptlet(%{
      LOAD_PATH = "./contained/#{@domain.name}/#{@name}"
      $: << "./lib/"
      $: << LOAD_PATH
      $service = { :name => "#{@name.to_s}", :full_name => "#{@full_name.to_s}", :domain => "#{@domain.name.to_s}" }
      
      require "container_logger"
      
      class ServiceManager
        def all_methods; []; end
        def self.exposed_methods(*meths)
          if meths.class==Array
            define_method("all_methods") { meths }
          else
            define_method("all_methods") { [meths] }
          end
        end
      end

      require 'drb'
      DRb.start_service
      $provider = DRbObject.new(nil, 'druby://127.0.0.1:#{@port}')
            
      require "#{@path}/startup.rb"
    })
    # Gather Service meta-data
    @meta_data.gather()
    
    @started = true
    ContainerLogger.debug "#{@full_name} booted succesfully!".console_green

    return self
  end

  # Invoke an certain method inside the service codebase
  #  
  # @todo: include blocks for invocation
  def invoke(method_name, *args, &block)
    arg   = Marshal.dump(args)
    blck  = Marshal.dump(block)
     
    if @meta_data.exposed_methods.include?(method_name.to_s)
      if args.size>0
        return @runtime.runScriptlet(%{
          arg = Marshal.load('#{arg}')
          $service_manager.#{method_name}(arg)
        })
      else
        @runtime.runScriptlet(%{$service_manager.#{method_name}()})      
      end
    else
      raise Exception.new("#{method_name} not available on #{@domain.name}::#{@name}")
    end
  end
  
  # restart the entire service
  #
  def restart()
    shutdown()
    startup()
  end
  
  # shutdown the service
  #
  def shutdown()
    raise Exception.new("Not implemented") 
  end
  
  # Inject code into the service: Remove ?!
  #
  def __inject(str)
   raise Exception.new("No Runtime defined for: #{@full_name}") if @runtime.nil?
   
   @runtime.runScriptlet(str)
  end
end