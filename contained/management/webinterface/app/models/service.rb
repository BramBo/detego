require 'yaml'
class Service
  attr_reader :domain, :name, :methods, :variables, :parent_route
  def initialize(name, domain)
    @name         = name
    @domain       = domain
    @parent_route = @domain
    
    meta_data     = $provider.for(@domain.name, @name).get_meta_data()
    
    @methods      = meta_data[:service_methods]
    @variables    = {}
    
    meta_data[:exposed_variables].each do |k, v|
        @variables[k] ||= {}
        if v.class==Array
          v.each { |vv| @variables[k][vv] = eval("$provider.for(domain.name, name).#{vv}()") }
        else
          @variables[k][v] = eval("$provider.for(domain, name).#{v}()") || "nil"
        end
    end
  end
  
  def inspect
    @name
  end
  
  def to_s
    @name    
  end
end
