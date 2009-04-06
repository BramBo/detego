require "domain"

class Container
  def initialize
    @domains    = Hash.new
    @path       = SERVICES_PATH
        
    # find exisiting domains and services
    Dir.new(@path).each do |domain|
      domain_dir = "#{@path}/#{domain}/"
      next if domain =~ /^\.{1,2}/ || !File.directory?(domain_dir) 
      
      Dir.new("#{@path}/#{domain}").each do |service|
        service_dir = "#{@path}/#{domain}/#{service}"
        next if service =~ /^\.{1,2}/ || !File.directory?(service_dir) 
         add_domain(domain.to_sym).add_service(service.to_sym)
      end
    end
    
    # now start all the services
    find(:all).each do |k,d| 
      d.find(:all).each do |n, s|
        s.start()
      end
    end
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
    # @todo: remove directory and underlying services
    @domains[name].remove
    @domains.delete(name)
    
    ContainerLogger.warn "Deleted domain #{name} (#{name.class})"
    true
  end
end