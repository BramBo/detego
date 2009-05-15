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
require "service_meta_data"
require 'drb'    
require 'drb/acl'

class Service
  attr_reader :name, :path, :full_name, :meta_data, :port_in, :port_out, :domain
  attr_accessor :runtime, :status
    
  # Runtimes have been transfered to service no a runtime foreach domain. 
  def initialize(name, domain)
    raise Exception.new("#{name} is not a valid service name") unless valid_directory_name(name.to_s)
        
    @name       = name
    @booted     = false
    @domain     = domain
    @full_name  = "#{domain.name}::#{@name}"
    @path       = "#{SERVICES_PATH}/#{domain.name}/#{@name}"
    @port_in    = $port_start+=1
    @port_out   = $port_start+=1
    @status     = "stopped"
    # @todo: Expand with org.jruby.RubyInstanceConfig        
    @runtime    = JJRuby.newInstance()
        
    # Create the domain directory if not present
    FileUtils.mkdir_p(@path, :mode => 0755)
    @runtime.runScriptlet(%{
      CONTAINER_PATH  = "#{CONTAINER_PATH}"
      LOAD_PATH       = "#{CONTAINER_PATH}/contained/#{@domain.name}/#{@name}"
      $: << "#{CONTAINER_PATH}/lib/"
      $: << LOAD_PATH
      $service = { :name => "#{@name.to_s}", :full_name => "#{@full_name.to_s}", :domain => "#{@domain.name.to_s}", :path => "#{@path}" }

      require "container_logger"
      ServiceLogger.service="#{@domain.name}_#{@name}"
      Object.send(:remove_const, :STDERR)
      Object.send(:remove_const, :STDOUT)
      $stderr = STDERR = File.open('#{CONTAINER_PATH}/log/#{@domain.name}_#{@name}.log', 'w+')
      $stdout = STDOUT = File.open('#{CONTAINER_PATH}/log/#{@domain.name}_#{@name}.log', 'w+')
      require 'drb'    
      require 'drb/acl'      
      
      class ServiceManager
        def status=(str)     
          $provider.for("#{@domain.name}".to_sym, "#{@name.to_sym}".to_sym).status = str
        end
        def status
          $provider.for("#{@domain.name}".to_sym, "#{@name.to_sym}".to_sym).status
        end
        def start()
          self.status="started" 
        end        

        def self.all_parameter_methods; @@p ||= Hash.new; end
        def all_methods; []; end
        def self.exposed_methods(*meths)
          if meths.class==Array
            define_method("all_methods") { meths }
          else
            define_method("all_methods") { [meths] }
          end
        end
        def self.has_parameters(meth, *params)
          all_parameter_methods[meth.to_s] = params.to_a
        end
        
        def self.limit_expose_to(pr = [])
          @@l = (pr.class==Array) ? pr :  [pr] unless pr.nil?
        end
        def limits; @@l ||= []; end
      end
      
      begin                
          require 'initialize'
      rescue LoadError 
        begin
          require 'service_manager'
        rescue LoadError
          raise Exception.new("Neither initialize or ServiceManager could be loaded for #{@full_name}")
        end
      end  
    })
    
    # And finally set the meta-data for the service
    @meta_data  = ServiceMetaData.new(self)
    ContainerLogger.debug "Service added #{domain.name}::#{name}"
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
  #  * Finally setsup the bidirectional communication for this service.
  #
  # After this 'code injection' the drb comm. channel gets made available in this class.
  # And the start() method is invoke on the newly setup runtime
  #
  def start
    raise Exception.new("Already started #{@full_name}")          unless @status =~ /stopped/i
    
    # Boot it            
    @runtime.runScriptlet(%{            
      DRb.install_acl(ACL.new( %w[deny all
        allow localhost 
        allow 127.0.0.1] ))
      @serv = DRb.start_service "druby://127.0.0.1:#{@port_out}", ($service_manager=ServiceManager.new)
      $provider = DRbObject.new(nil, 'druby://127.0.0.1:#{@port_in}')      
      $provider.for("#{@domain.name}".to_sym, "#{@name.to_sym}".to_sym).status = "Booting.."
    })
    
    @service_manager = DRbObject.new(nil, "druby://127.0.0.1:#{@port_out}")
    
    # Gather Service meta-data
    @meta_data.gather()
    @runtime.runScriptlet(%{
      @starting_thread = Thread.new do
        $service_manager.start()
      end      
    })
    
    ContainerLogger.debug "#{@full_name} booted succesfully!".console_green

    return self
  end

  # Invoke an certain method inside the service codebase
  #  
  # @todo: include blocks for invocation
  def invoke(method_name, *args, &block)
    raise Exception.new("Service #{@name} not started!") if @status =~ /stopped/i 
    arg   = Marshal.dump(args)  
    blck  = Marshal.dump(block)

    if @meta_data.service_methods[:exposed].to_a.flatten.include?(method_name.to_s) ||  @meta_data.exposed_variables.to_a.flatten.collect{|s| s = s.to_s }.include?(method_name.to_s)
      ContainerLogger.debug "Invoking #{method_name} #{@full_name} ServiceManager".console_green  

      # FIXME should be able to be done otherwise
      begin
        if !args.nil? && !args.first.nil?
          if block
            return @runtime.runScriptlet(%{
              arg = Marshal.load('#{arg}')
              $service_manager.#{method_name}(arg) { Marshal.load('#{blck}') }
            })          
          else 
            query = args.map{|e| e = %{"#{e}"} }.join(", ")
            return @runtime.runScriptlet(%{
              eval(%[$service_manager.#{method_name}(#{query})])
            })
          end
        else
          @runtime.runScriptlet(%{$service_manager.#{method_name}()})      
        end
      rescue Exception => e
        return nil
      end
    else
      ContainerLogger.warn "Invoking #{method_name} #{@full_name} but is a no(n/t) (exposed) method"
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

    data = {}
    @meta_data.get_readable_var_values
    @meta_data.readable_var_values.each do |key, val|
        data[key] = val
    end
    f = File.new("#{@path}/service_data.yml", "w+")
    f.puts data.to_yaml
    f.close

    begin
      @runtime.runScriptlet(%{
        begin; $service_manager.shutdown(); rescue => e; end

        @serv.stop_service
        begin
          require 'shutdown'
        rescue LoadError => e
          ContainerLogger.warn "Skipping shutdown script for #{@full_name}..."
        end
        @starting_thread.exit
      })
    rescue => e
      ContainerLogger.warn "#{@full_name} error shutting down: #{e}"
    end
    
    @runtime    = nil    
    @runtime    = JJRuby.newInstance()        
    @status     = "stopped"
    @meta_data.reset
    ContainerLogger.debug "#{@full_name} shutdown"
    true
  end

  # install
  # 
  def install()
    # this must pass to be validates as a serice!
    begin 
     @runtime.runScriptlet(%{
       Object.send(:remove_const, :CONTAINER_PATH) if Object.const_defined? :CONTAINER_PATH
       Object.send(:remove_const, :LOAD_PATH)      if Object.const_defined? :LOAD_PATH 
       CONTAINER_PATH  = "#{CONTAINER_PATH}"
       LOAD_PATH       = "#{CONTAINER_PATH}/contained/#{@domain.name}/#{@name}"
       $: << "#{CONTAINER_PATH}/lib/"
       $: << LOAD_PATH
       $service = { :name => "#{@name.to_s}", :full_name => "#{@full_name.to_s}", :domain => "#{@domain.name.to_s}" }

       class ServiceManager
         def status=(str)     
           $provider.for("#{@domain.name}".to_sym, "#{@name.to_sym}".to_sym).status = str
         end
         def status
           $provider.for("#{@domain.name}".to_sym, "#{@name.to_sym}".to_sym).status
         end
         def start()
           self.status="started" 
         end        

         def self.all_parameter_methods; @@p ||= Hash.new; end
         def all_methods; []; end
         def self.exposed_methods(*meths)
           if meths.class==Array
             define_method("all_methods") { meths }
           else
             define_method("all_methods") { [meths] }
           end
         end
         def self.has_parameters(meth, *params)
           all_parameter_methods[meth.to_s] = params.to_a
         end

         def self.limit_expose_to(pr = [])
           @@l = (pr.class==Array) ? pr :  [pr] unless pr.nil?
         end
         def limits; @@l ||= []; end
       end
       
        begin                
            require 'initialize'
        rescue LoadError 
          begin
            require 'service_manager'
          rescue LoadError
            raise Exception.new("Neither initialize or ServiceManager could be loaded for #{@full_name}")
          end
        end
      })
      ContainerLogger.debug "#{@domain.name}::#{@name} installed succesfully"
      @runtime    = nil    
      @runtime    = JJRuby.newInstance()
      
      # No problem if this fails
      @runtime.runScriptlet(%{
         begin                
           require 'install'
         rescue LoadError => e;end       
      })
            
      true
    rescue Exception => e
      ContainerLogger.warn "#{@domain.name}::#{@name} rescued, before installing: #{e}"      
      @domain.remove(@name) unless @name.nil?
      ContainerLogger.debug "Installation rolled back"
      e      
    rescue LoadError => e
      ContainerLogger.warn "#{@domain.name}::#{@name} rescued, before installing: #{e}"            
      @domain.remove(@name) unless @name.nil?
      ContainerLogger.debug "Installation rolled back"      
      e      
    rescue => e
      ContainerLogger.warn "#{@domain.name}::#{@name} rescued, before installing: #{e}"      
      @domain.remove(@name) unless @name.nil?
      ContainerLogger.debug "Installation rolled back"      
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
    true
  end


  # Just here for code prettyness
  def started?
    @status =~ /!stopped/
  end
  
  # Inject code into the service: Remove ?!
  #
  def __inject(str)
   raise Exception.new("No Runtime defined for: #{@full_name}") if @runtime.nil?
   
   @runtime.runScriptlet(str)
  end
end