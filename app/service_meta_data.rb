class ServiceMetaData
  attr_reader :exposed_methods, :exposed_variables
  
  def initialize(service)
    @service = service
  end
  
  def gather
    @service.runtime.runScriptlet(%{       
      $service_manager = ServiceManager.new      
    })  
    
    @exposed_methods =@service.runtime.runScriptlet(%{
      $service_manager.all_methods
    })
    @exposed_methods.each_with_index{|m, i| @exposed_methods[i] = m.to_s}
    
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