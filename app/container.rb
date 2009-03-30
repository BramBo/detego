require "domain"

class Container
  def initialize
    @domains        = Hash.new
  end
  
  def find(domain_name)
    return @domains if domain_name == :all
    
    @domains[domain_name] || nil
  end
  
  def add_domain(name)
    @domains[name] = Domain.new(name, self)
  end
end