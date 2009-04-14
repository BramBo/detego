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