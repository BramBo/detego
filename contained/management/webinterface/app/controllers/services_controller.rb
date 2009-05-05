class ServicesController < ApplicationController
  def show
    @domain   = Domain.find(params[:domain_id])
    @service  =   @domain.service(params[:id])
  end
  
  def new
    @domain   = Domain.find(params[:domain_id])    
  end
  
  def create
    @domain   = Domain.find(params[:domain_id])
    # upload and place the shiznit

    @results = @domain.new_service(params)

    # create the file path

    # write the file
 #   File.open(path, "wb") { |f| f.write(upload['datafile'].read) }    
    render :action => "create"
  end
  
  
  ## RPC Methods
  def invoke 
    @domain           = params[:domain_id]
    @service          = params[:id]    
    @method           = params[:method].to_s        

    begin
      @value = eval("$provider.for('#{@domain}'.to_sym, '#{@service}'.to_sym).#{@method}")
      ContainerLogger.debug @value
      @value = @value.join("<br />") if @value.class == Array
    rescue Exception => e
      @value = "error;#{e.message.capitalize}"
    rescue => e
      @value = "error;#{e.message.capitalize}"
    end
    
    if @method =~ /remove_service\(.+?\)/i && @value == true
      flash[:notice] = "Succesfully removed service #{@service}"
    end
    
    render :action => "invoke.js.erb", :layout => false
  end

  def update_details
    @domain   = Domain.find(params[:domain_id])
    @service  = @domain.service(params[:id])
    
    render :action => "_details", :layout => false
  end

  def status 
    @domain           = params[:domain_id]
    @service          = params[:id]    

    begin
      @value    = $provider.for(@domain.to_sym, @service.to_sym).status()
    rescue Exception => e
      @value = "error;#{e.message.capitalize}"
    rescue => e
      @value = "error;#{e.message.capitalize}"
    end
          
    render :action => "status.js.erb", :layout => false
  end  
end
