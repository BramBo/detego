class FileSystemPoller
  attr_reader :current_structure, :old_structure
  
  def initialize(path)
    @path     = path
    get_current_structure
  end
  
  def poll
    begin
      @old_structure = @current_structure
      get_current_structure
    
      # check for missing entities in the old directory tree
      (@old_structure.keys - @current_structure.keys).each do |d|
        # domain got deleted !
        $provider.remove_domain(d.to_sym)
        ContainerLogger.warn "Domain #{d} got deleted!"        
      end
    
      # Check for new entities in the current directory tree
      (@current_structure.keys - @old_structure.keys).each do |d|
        # found new domain
        @current_structure[d].each do |s|
          $provider.add_service(d.to_sym, s.to_sym) 
          ContainerLogger.debug "New service discovered! #{d}::#{s}"          
        end
      end

      # finally check for deleted services within the current domains
      @current_structure.each do |k, d|

        unless @old_structure[k].nil?
          (@current_structure[k] - @old_structure[k]).each do |s|
            $provider.remove_service(d.to_sym, s.to_sym)             
            ContainerLogger.warn "Service directory removed! #{k}::#{s}"
          end
      
          (@old_structure[k] - @current_structure[k]).each do |s|
            $provider.remove_service(d.to_sym, s.to_sym)             
            ContainerLogger.debug "New service discovered! #{k}::#{s}"
          end
        end
      end
    rescue => ex
      ContainerLogger.error ex, 1
    end
  end
  
  private 
    def get_current_structure
      @current_structure = {}
      Dir.new(@path).each do |domain|
        domain_dir = "#{@path}/#{domain}/"
        next if domain =~ /^\.{1,2}/ || !File.directory?(domain_dir) 
        read_dir(domain)
      end
      @current_structure
    end
    
    def read_dir(domain)
      Dir.new("#{@path}/#{domain}").each do |service|
        service_dir = "#{@path}/#{domain}/#{service}"
        next if service =~ /^\.{1,2}/ || !File.directory?(service_dir) 
          @current_structure[domain] ||= []
          @current_structure[domain] << service
      end
    end
end