require "domain"

class Container
  def initialize
    @domains    = Hash.new
    @path       = SERVICES_PATH

    # Don't initiate the services when testing
    initiate_installed_services() unless ENV["DETEGO_ENV"] =~ /test/i   
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
  
  def remove(name=nil)
    if name.nil?
      @domains.each do |n, domain|
        domain.remove
        @domains.delete(n)      
      end
    else
      @domains[name].remove
      @domains.delete(name)
    end
    
    ContainerLogger.warn "Deleted domain #{name} (#{name.class})"
    true
  end
  
  private 
   def initiate_installed_services()
     # find exisiting domains and services
     Dir.new(@path).each do |domain|
       next if domain =~ /^\.{1,2}/ || !File.directory?("#{@path}/#{domain}/") 
 
       Dir.new("#{@path}/#{domain}").each do |service|
         next if service =~ /^\.{1,2}/ || !File.directory?("#{@path}/#{domain}/#{service}") 
          add_domain(domain.to_sym).add_service(service.to_sym)
       end
     end

     # now start all the services
     find(:all).each do |k,d| 
       d.find(:all).each do |k,s|
         s.start()
       end
     end
    end 
end