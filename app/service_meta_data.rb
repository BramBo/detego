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
require "yaml"

class ServiceMetaData
  attr_reader :service_methods, :exposed_variables, :readable_var_values, :limit_expose_to
  
  def initialize(service)
    @service = service
  end
  
  def reset
    @expose               = []
    @readable_var_values  = {}
    @service_methods      = {:all  => [], :exposed => []}
    @exposed_variables    = {:both => [], :read    => [], :write => []}
  end
  
  # Figure out the available methods and variables for this service 
  # By creating a new service manager(to not interfere with the running DRB process)  
  def gather
    @exposed_variables = Marshal.load(@service.runtime.runScriptlet(%{
      vs = {:both => [], :read => [], :write => []}
      
      $service_manager.instance_variables.each do |m|
        r_meth = m.gsub(/\@/, "").to_sym
        w_meth = (m.gsub(/\@/, "")+"=").to_sym

        if $service_manager.respond_to?(r_meth) && $service_manager.respond_to?(w_meth)
          vs[:both]   << r_meth.to_s         
          vs[:both]   << w_meth.to_s              
          
        elsif $service_manager.respond_to?(w_meth)
          vs[:write]  << w_meth.to_s
        elsif $service_manager.respond_to?(r_meth)
          vs[:read]   << r_meth.to_s
        end
      end
      
      Marshal.dump(vs)
    }))


    @expose = Marshal.load(@service.runtime.runScriptlet(%{Marshal.dump($service_manager.limits.map{|e| e = e.to_s.downcase.to_sym})}))
    
    get_readable_var_values()
    if(File.exists?("#{@service.path}/service_data.yml"))
      data = YAML::load( File.open( "#{@service.path}/service_data.yml" ) )
      data.each do |k, v|
        @readable_var_values[k.to_sym] = v
        @service.runtime.runScriptlet(%{$service_manager.instance_variable_set("@#{k}", "#{v}")})
      end
      
      # now delete it !
      File.delete("#{@service.path}/service_data.yml")
    end
    
    @service_methods = Marshal.load(@service.runtime.runScriptlet(%{
      m = {:all => [], :exposed => []}
      $service_manager.all_methods.each {|e| m[:exposed] << [e.to_s, $service_manager.class.all_parameter_methods[e.to_s] || [] ]}
      
      m[:all] = ($service_manager.public_methods-Object.public_instance_methods) - $service_manager.all_methods.map{|e| e.to_s } - ["start", "all_methods", "stop", "status=", "status", "limits", "limit_expose_to"]
      
      Marshal.dump(m)
    }))
    
    @service_methods[:all] -= (@exposed_variables[:read] + @exposed_variables[:both] + @exposed_variables[:write])
  end
  
  def get_readable_var_values
    @readable_var_values = Marshal.load(@service.runtime.runScriptlet(%{
      vs = {}
      
      $service_manager.instance_variables.each do |m|
        r_meth = m.gsub(/\@/, "").to_sym
        vs[r_meth] = instance_eval("$service_manager."+r_meth.to_s+"()") if $service_manager.respond_to?(r_meth)
      end
      
      Marshal.dump(vs)
    }))
  end
end