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
        begin  
          add_domain(domain.to_sym).add_service(service.to_sym).start()
        rescue => e
          ContainerLogger.error e, 1
        end
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
    @domains.delete(name)
    ContainerLogger.warn "Deleted domain #{name} (#{name.class})"
    true
  end
end