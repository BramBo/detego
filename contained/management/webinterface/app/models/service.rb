class Service
  attr_reader :domain, :name, :methods, :variables
  def initialize(name, domain)
    @name       = name
    @domain     = domain
    
    meta_data   = $provider.for(@domain.name, @name).get_meta_data()
    @methods    = meta_data[:service_methods]
    @variables  = meta_data[:exposed_variables]
  end
  
  def inspect
    @name
  end
  
  def to_s
    @name    
  end
end
