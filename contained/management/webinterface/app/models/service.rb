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
            v.each do |vv| 
              if (k== :write)
               @variables[k][vv] = "-----"
              elsif (k== :both)
                next unless vv =~ /\=/
                @variables[k][vv] = eval("$provider.for(domain.name, name).#{vv.gsub(/\=/, "")}()")   
              else
                @variables[k][vv] = eval("$provider.for(domain.name, name).#{vv}()")
              end 
            end
          else
            if (k== :write)
             @variables[k][v]   = "-----"
            elsif (k== :both)
              next unless vv =~ /\=/              
              @variables[k][v]  = eval("$provider.for(domain.name, name).#{v.gsub(/\=/, "")}()")           
            else
              @variables[k][v] = eval("$provider.for(domain.name, name).#{v}()")
            end
          end            
          
       rescue Exception => e; next
       rescue => e;           next
      end          
    end unless meta_data[:exposed_variables].nil?
    
  end
  
  def inspect
    @name
  end
  
  def to_s
    @name    
  end
  
  def self.supported_file_types
    $provider.on(:core, :deployer).supported_types()
  end
end
