class ServicesController < ApplicationController
  def show
    @domain   = Domain.find(params[:domain_id])
    @service  = @domain.service(params[:id])
  end
  
  def invoke 
    
    @domain   = params[:domain_id]
    @service  = params[:id]    
    @method   = params[:method].to_s        

    @value    = eval("$provider.for('#{@domain}'.to_sym, '#{@service}'.to_sym).#{@method}")
    
    render :action => "invoke.js.erb", :layout => false
  end
end
