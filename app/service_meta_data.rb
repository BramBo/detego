class ServiceMetaData
  attr_reader :service_methods, :exposed_variables
  
  def initialize(service)
    @service = service
  end
  
  def gather
    @service.runtime.runScriptlet(%{       
      $service_manager = ServiceManager.new      
    })  
    
    @service_methods = {:all => [], :exposed => []}
    @service.runtime.runScriptlet(%{
      m = {:all => [], :exposed => []}
      $service_manager.all_methods.each {|e| m[:exposed] << e.to_s}
      m[:all]      = ($service_manager.public_methods-Object.public_instance_methods) - m[:exposed] - ["start", "all_methods", "stop"]
      m
    }).each {|k, v|
      v.each do |e|
        @service_methods[:all]     << e.to_s if k.to_s == "all"
        @service_methods[:exposed] << e.to_s if k.to_s == "exposed"
      end
    }

    @exposed_variables = {:both => [], :read => [], :write => []}    
    @exposed_variables = @service.runtime.runScriptlet(%{
      vs = {:read => [], :write => [], :both => [] }
      
      $service_manager.instance_variables.each do |m|
        r_meth = m.gsub(/\@/, "").to_sym
        w_meth = (m.gsub(/\@/, "")+"=").to_sym

        if $service_manager.respond_to?(r_meth) && $service_manager.respond_to?(w_meth)
          vs[:both]  << r_meth
        elsif $service_manager.respond_to?(w_meth)
          vs[:write] << r_meth
        elsif $service_manager.respond_to?(r_meth)
          vs[:read]  << r_meth
        end
      end
      vs
    })
  end
end