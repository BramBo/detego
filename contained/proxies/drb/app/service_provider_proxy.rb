require 'drb'
class ServiceProviderProxy
  include DRb::DRbUndumped  
      
  def on(domain, service)
    @domain  = domain.to_sym
    @service = service.to_sym
    self
  end
  
  def for(domain, service=nil)
    @domain  = (domain)   ? domain.to_sym   : nil
    @service = (service)  ? service.to_sym  : nil
    self
  end  
  
  def method_missing(method_name, *args, &block)
    raise Exception.new("Method(#{method_name}) not allowed from remote host!") if black_list.include?(method_name.to_s)

    if !@domain.nil? && !@service.nil?
      service_limited?(@domain, @service)
      
      puts %{$provider.on(:#{@domain}, :#{@service}).#{build_invoke_str(method_name, *args, &block)}} 
      r =  instance_eval(%{$provider.on(:#{@domain}, :#{@service}).#{build_invoke_str(method_name, *args, &block)}})
    elsif !@domain.nil?    
      r = instance_eval(%{$provider.for(:#{@domain}).#{build_invoke_str(method_name, *args, &block)}})      
    else
      r = instance_eval(%{$provider.#{build_invoke_str(method_name, *args, &block)}})
    end
    @domain = @service = nil
    return r
  end
  
  private 
   
   # We can't allow methods as add_service or remove_service to be called from anywhere !
   def black_list
    %w{add_service add_domain remove_service remove_domain start_service stop_service restart_service status=}
   end 
   
   def build_invoke_str(method_name, *args, &block)     
     if args && block
       return "#{method_name.to_s}(*#{args}, #{block})"
     elsif args
       return "#{method_name.to_s}(#{args})"
     elsif block
       return "#{method_name.to_s}(#{block})"
     else
       return "#{method_name.to_s}()"
     end
   end
   
   
   def service_limited?(d, s)
     l = []
     begin 
       l = $provider.for(d.to_sym, s.to_sym).expose_limit() || []
      rescue => e
        puts e
      end
      
     raise Exception.new("Can't reach over REST !") if (l.size() > 0 && !l.include?("rest"))      
   end
end