# Copyright (c) 2009 Bram Wijnands
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
class ServiceMetaData
  attr_reader :service_methods, :exposed_variables
  
  def initialize(service)
    @service = service
  end
  
  def reset
    @service_methods    = {:all => [] , :exposed => []}
    @exposed_variables  = {:both => [], :read => []   , :write => []}
  end
  
  def gather
    @service.runtime.runScriptlet(%{       
      $service_manager = ServiceManager.new      
    })  

    # todo: only instantiated variables are read, so attr_reader, _writer and _accessor have not much todo with this.
    @exposed_variables = Marshal.load(@service.runtime.runScriptlet(%{
      vs = {:both => [], :read => [], :write => []}
      
      $service_manager.instance_variables.each do |m|
        r_meth = m.gsub(/\@/, "").to_sym
        w_meth = (m.gsub(/\@/, "")+"=").to_sym

        if $service_manager.respond_to?(r_meth) && $service_manager.respond_to?(w_meth)
          vs[:both]  << r_meth.to_s
        elsif $service_manager.respond_to?(w_meth)
          vs[:write] << r_meth.to_s
        elsif $service_manager.respond_to?(r_meth)
          vs[:read]  << r_meth.to_s
        end
      end
      
      Marshal.dump(vs)
    }))
    
    @service_methods = Marshal.load(@service.runtime.runScriptlet(%{
      m = {:all => [], :exposed => []}
      $service_manager.all_methods.each {|e| m[:exposed] << [e.to_s, $service_manager.class.all_paramater_methods[e.to_s] || [] ]}
      
      m[:all] = ($service_manager.public_methods-Object.public_instance_methods) - $service_manager.all_methods.map{|e| e.to_s } - ["start", "all_methods", "stop"]
      
      Marshal.dump(m)
    }))
    

    @service_methods[:all] -= (@exposed_variables[:read] + @exposed_variables[:both] + @exposed_variables[:both].map{|e| "#{e}="} + @exposed_variables[:write].map{|e| "#{e}="})
  end
end