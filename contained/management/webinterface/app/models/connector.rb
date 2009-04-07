class Connector
  attr_reader :domains
  
  def initialize
    @domains = []
    $provider.get_domains().each do |n|
      @domains << Domain.new(n)
    end
  end
  
  def self.domains
    domains = []
    $provider.get_domains().each do |n|
      domains << Domain.new(n)
    end
    
    return domains
  end
end
