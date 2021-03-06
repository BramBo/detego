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
require "service_meta_data"
require "service_code_base_initializer"
require 'drb'    
require 'drb/acl'

class Service
  attr_reader :name, :path, :full_name, :meta_data, :port_in, :port_out, :domain, :service_manager, :config
  attr_accessor :runtime, :status
    
  # Runtimes have been transfered to service no a runtime foreach domain. 
  def initialize(name, domain)
    raise Exception.new("#{name} is not a valid service name") unless valid_directory_name(name.to_s)

    @name             = name
    @booted           = false
    @domain           = domain
    @full_name        = "#{domain.name}::#{@name}"
    @path             = "#{SERVICES_PATH}/#{domain.name}/#{@name}"
    @port_in          = $port_start+=1
    @port_out         = $port_start+=1
    @status           = "stopped"
    # @todo: Expand with org.jruby.RubyInstanceConfig        
    @runtime          = JJRuby.newInstance()
    @service_manager  = DRbObject.new(nil, "druby://127.0.0.1:#{@port_out}")
    
    # 
    init_code_base()
    @config = Marshal.load(@runtime.runScriptlet(%{Marshal.dump(ServiceCodeBase::Initializer.config)}))    
    
    # And finally set the meta-data for the service
    @meta_data  = ServiceMetaData.new(self)
    
    DRb.install_acl(ACL.new(%w[deny all allow localhost allow 127.0.0.1]))
    DRb.start_service "druby://127.0.0.1:#{@port_in}", ServiceProvider.new(@domain.container, self)    
    
    ContainerLogger.debug "Service added #{@full_name}"
  end

  # Start/boot the service 
  # 
  # This method injects alot of code inside the Service runtime.
  # Basicly what it does:
  #  * Sets Paths(and inserting them in $:) 
  #  * Makes basic info avaliable (Service path/name/domain/full_name)
  #  * Sets up the logging(Making ServiceLogger available) STDERR+STDOUT get mapped on ROOT/log/domain_service.log
  #  * Creates a ServiceManager class making methods available to set(&get) meta-data
  #  * Gets the initialize script ready if it isnt avaialble it will try to load service_manager.rb
  #  * Finally sets up the bidirectional communication for this service.
  #
  # After this 'code injection' the drb comm. channel gets made available in this class.
  # And the start() method is invoke on the newly set up runtime
  #
  def start
    raise Exception.new("Already started #{@full_name}")          unless @status =~ /stopped/i
        
    # Boot it
    @runtime.runScriptlet(%{
      __setup_DRb_services
      $service_manager
    })
    # Gather Service meta-data
    @meta_data.gather()  
    @runtime.runScriptlet(%[ @starting_thread = Thread.new { $service_manager.start() } ])

    notify_observable_base(ObservableBase::SERVICE_STARTED, {:domain => @domain.name, :service => @name})
    ContainerLogger.notify "#{@full_name} booted succesfully!"
    return self
  end

  # Invoke a certain method inside the service codebase
  #  
  # FIXME make it possible to use blocks with invocations
  def invoke(method_name, *args, &block)
    raise Exception.new("Service #{@name} not started!") if @status =~ /stopped/i 
    result  = nil
    arg     = Marshal.dump(args)  
    blck    = Marshal.dump(block)

    if @meta_data.service_methods[:exposed].to_a.flatten.include?(method_name.to_s) ||  @meta_data.exposed_variables.to_a.flatten.collect{|s| s = s.to_s }.include?(method_name.to_s)
      ContainerLogger.debug "Invoking #{method_name} #{@full_name} ServiceManager".console_green  

      # FIXME Nasty! should be able to be done otherwise
      begin
        if !args.nil? && !args.first.nil?
          if block
            result =  Marshal.load(@runtime.runScriptlet(%{
              arg = Marshal.load('#{arg}')
              Marshal.dump($service_manager.#{method_name}(arg) { Marshal.load('#{blck}') })
            }))
            notify_observable_base(ObservableBase::SERVICE_INVOKED, {:domain => @domain.name, :service => @name, :method => method_name, :returned => result})
          else 
            query = args.map{|e| e = %{"#{e}"} }.join(", ")
            result = Marshal.load(@runtime.runScriptlet(%{
              Marshal.dump(eval(%[$service_manager.#{method_name}(#{query})]))
            }))
            notify_observable_base(ObservableBase::SERVICE_INVOKED, {:domain => @domain.name, :service => @name, :method => method_name, :args => query, :returned => result})
          end
        else      
          result = Marshal.load(@runtime.runScriptlet(%{Marshal.dump($service_manager.#{method_name}())}))
          notify_observable_base(ObservableBase::SERVICE_INVOKED, {:domain => @domain.name, :service => @name, :method => method_name, :returned => result})
        end
      rescue Exception => e
        return nil
      end
      @meta_data.get_readable_var_values()
      return result      
    else
      ContainerLogger.warn "Invoking #{method_name} #{@full_name} but is not a(n) (exposed) method"
      raise Exception.new("#{method_name} not available on #{@domain.name}::#{@name}")
    end    
  end
  
  # restart the entire service
  #
  def restart()
    shutdown()
    start()
  end
  
  # shutdown the service
  # 
  # @todo: Look into rails to figure out how to force exit WEBrick/proxies::rest/Mongrel and alike..
  def shutdown()
    return if @status=~/stopped/i

    unless @config.dont_save
      data = {}
      @meta_data.get_readable_var_values
      @meta_data.readable_var_values.each do |key, val|
          data[key] = val
      end
            
      f = File.new("#{@path}/service_data.yml", "w+")
      f.puts data.to_yaml
      f.close
    end

    begin
      @runtime.runScriptlet(%{
        begin; $service_manager.shutdown(); rescue => e; end

        @serv.stop_service
        begin
          require 'shutdown'
        rescue LoadError => e
          ContainerLogger.debug "Skipping shutdown script for #{@full_name}..."
          ServiceLogger.warn    "No Shutdown script present."
        end
        @starting_thread.exit
      })
    rescue => e
      ContainerLogger.error "#{@full_name} error shutting down: #{e}"
    end
    notify_observable_base(ObservableBase::SERVICE_STOPPED, {:domain => @domain.name, :service => @name})
    
    @runtime.runScriptlet(%{ Thread.kill(@starting_thread) })
    @runtime    = nil
    @runtime    = JJRuby.newInstance()        
    init_code_base()
    @status     = "stopped"
    @meta_data.reset
    ContainerLogger.notify "#{@full_name} shutdown"
    true
  end

  # install
  # 
  def install()
    # this must pass to be validated as a service!
    begin 
      init_code_base()
      ContainerLogger.debug "#{@domain.name}::#{@name} installed succesfully"
      @runtime    = nil    
      @runtime    = JJRuby.newInstance()
      
      # No problem if this fails
      @runtime.runScriptlet(%{
         begin                
           require 'install'
         rescue LoadError => e;end       
      })

      init_code_base()
      notify_observable_base(ObservableBase::SERVICE_INSTALLED, {:domain => @domain.name, :service => @name})
      true
    rescue Exception => e
      ContainerLogger.error "#{@domain.name}::#{@name} rescued, before installing: #{e}"      
      @domain.remove(@name) unless @name.nil?
      ContainerLogger.warn "Installation rolled back"
      e      
    rescue LoadError => e
      ContainerLogger.error "#{@domain.name}::#{@name} rescued, before installing: #{e}"            
      @domain.remove(@name) unless @name.nil?
      ContainerLogger.debug "Installation rolled back"      
      e      
    rescue => e
      ContainerLogger.error "#{@domain.name}::#{@name} rescued, before installing: #{e}"      
      @domain.remove(@name) unless @name.nil?
      ContainerLogger.warn "Installation rolled back"      
      e
    end
  end

  # Uninstall
  # 
  def uninstall()
     shutdown() unless @status =~ /stopped/i
     
     @status = "uninstalling"
     r = @runtime.runScriptlet(%{
       begin                
         require 'uninstall'
       rescue LoadError;end     
     })
    @runtime    = nil

     begin 
       FileUtils.rm_rf("#{SERVICES_PATH}/#{@domain.name}/#{@name}")
     rescue Exception => e
       Containerlogger.warn e,2
     rescue  e
       Containerlogger.warn e,2
     end
    ContainerLogger.debug "#{@domain.name}::#{@name} uninstalled succesfully"
    
    notify_observable_base(ObservableBase::SERVICE_UNINSTALLED, {:domain => @domain.name, :service => @name})    
    true
  end

  # Just here for code prettyness
  def started?
    @status =~ /!stopped/
  end
  
  
  # Inject code into the service: Remove ?!
  def _inject(str)
   raise Exception.new("No Runtime defined for: #{@full_name}") if @runtime.nil?
   
   @runtime.runScriptlet(str)
  end
  
  def __inject(str)
   raise Exception.new("No Runtime defined for: #{@full_name}") if @runtime.nil?
   
   # notice the different method on the JRuby object (this is the original!)
   @runtime.evalScriptlet(str)
  end  

  def to_s;    @name; end
  def inspect; @name; end  

  private 
  def init_code_base
    # Setup the context dependend variables. Nasty..
    @runtime.runScriptlet(%{
      
     DETEGO_VERSION = "#{DETEGO_VERSION}"      
     
     # Set up the load paths
     CONTAINER_PATH, LOAD_PATH = "#{CONTAINER_PATH}", "#{CONTAINER_PATH}/contained/#{@domain.name}/#{@name}"
     $: << "#{CONTAINER_PATH}/lib/" << "#{CONTAINER_PATH}/lib/service" << LOAD_PATH

     $org_port      = #{$org_port}

     # Default service information, available troughout the service
     $service = { :name       => "#{@name.to_s}", 
                  :full_name  => "#{@full_name.to_s}", 
                  :domain     => "#{@domain.name.to_s}",  
                  :path       => "#{@path}", 
                  :port_in    => #{@port_in.to_i}, 
                  :port_out   => #{@port_out.to_i} } 
    })
    
    # Inject the files content as if it is a String
    nasty_file_string = File.open("#{SERVICE_LIBRARY_PATH}/service_code_base_initialize.rb").map.join.to_s
    @runtime.runScriptlet(nasty_file_string)
  end
  
  def notify_observable_base(event, details={})
    ObservableBase.instance().update(self, ObservableBase::SERVICE, event, details)
  end  
end