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
      $service_manager.instance_variables
    })
  end
end