require 'drb'
# OMG it's a replica !
class ServiceProviderProxy
  include DRb::DRbUndumped  
      
  def on(domain, service)
    @domain  = domain.to_sym
    @service = service.to_sym
    self
  end
  
  def method_missing(method_name, *args, &block)
    required_set?

    instance_eval(%{$provider.on(:#{@domain}, :#{@service}).#{method_name.to_s}()})
  end
  
  private 
   def required_set?
     raise Exception.new("Domain and ot Service not set!") if (@service.nil? || @domain.nil?)
   end
   
   # We can't allow methods as add_service or remove_service to be called from anywhere
   # If you would, write your own
   def black_list
    %w{add_service add_domain remove_service remove_domain start_service stop_service restart_service}
   end 
end