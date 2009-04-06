class Domain
  attr_reader :name

  def self.find(name)
    return Domain.new(name.to_sym)
  end

  def initialize(name)
    @name = name.to_sym
  end

  def services()
    servs = []
    $provider.for(@name.to_sym).get_services().each do |n|
      servs << Service.new(n, self)
    end
    
    servs
  end
  
  def service(service_name)
    $provider.for(@name.to_sym).get_services().each do |n|
      return Service.new(n, self) if service_name.downcase.to_sym == n
    end
  end
  
  def inspect
    @name
  end
  
  def to_s
    @name
  end
end
