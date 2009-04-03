require "domain"

class Container
  def initialize
    @domains        = Hash.new
  end
  
  def find(domain_name)
    return @domains if domain_name == :all
    
    domain = @domains[domain_name]
    return domain unless domain.nil?
    
    ContainerLogger.warn "Unexisting domain called: #{domain_name}"
    nil
  end
  
  def add_domain(name)
    @domains[name] = @domains[name] || Domain.new(name, self)
  end
  
  def remove(name)
    @domains.delete(name)
    ContainerLogger.warn "Deleted domain #{name} (#{name.class})"
    true
  end
end