class DomainsController < ApplicationController
  def index
    @domains  = Connector.new().domains
  end
  
  def new
    @result = Domain.create(params[:name])
    render :action => "empty", :layout => false
  end
  
  def show
    @domain   = Domain.find(params[:id])
    @services = @domain.services
  end
  
  def locate
    @result  = Connector.locate(params[:query]||params[:search])  
    render :action => "locate", :layout => false
  end
  
  def delete
    @result = Domain.remove(params[:id])
    render :action => "empty", :layout => false    
  end
end
