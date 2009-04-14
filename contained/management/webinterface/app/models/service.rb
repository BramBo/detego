class Service
  attr_reader :domain, :name, :methods, :variables, :parent_route, :status
  def initialize(name, domain)
    @name         = name
    @domain       = domain
    @parent_route = @domain
    
    meta_data     = $provider.for(@domain.name, @name).get_meta_data()
    
    @methods      = meta_data[:service_methods]
    @variables    = {}
    @status       = $provider.for(@domain.name.to_sym, @name.to_sym).status();
    
    meta_data[:exposed_variables].each do |k, v|
      begin       
          @variables[k] ||= {}          
          if v.class==Array
            v.each { |vv| @variables[k][vv] = (k != :write) ? eval("$provider.for(domain.name, name).#{vv}()") : "-----" }
          else
            @variables[k][v] = (k != :write) ? eval("$provider.for(domain, name).#{v}()") || "nil" : "-----"
          end            
          
       rescue Exception => e;  next
       rescue => e;            next
      end          
    end unless meta_data[:exposed_variables].nil?
    
  end
  
  def inspect
    @name
  end
  
  def to_s
    @name    
  end
end
