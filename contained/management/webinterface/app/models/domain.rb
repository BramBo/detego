class Domain
  attr_reader :name

  def self.create(name)     
    return $provider.add_domain(name.to_sym) 
  end    

  def self.find(name)
    return Domain.new(name.to_sym)
  end
  
  def self.remove(name)
    return $provider.remove_domain(name.to_sym)     
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
  
  def new_service(params)
    file      =  params[:file].original_filename
    
    if(file =~ /\.(#{Service.supported_file_types})$/i)
      path = "#{CONTAINER_PATH}/contained/#{@name}/#{file.gsub(/\/([^\/]+?$)/, '$1')}"
      File.open(path, "wb") { |f| f.write(params['file'].read) }
      
      # Now tell the deployer to poll the filesystem and all is well !
      $provider.on(:core, :deployer).poll()      
      $provider.on(:core, :deployer).poll().to_s
    else
      false
    end
  end
  
  def inspect
    @name
  end
  
  def to_s
    @name
  end
end
