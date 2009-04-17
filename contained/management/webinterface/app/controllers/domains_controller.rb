class DomainsController < ApplicationController
  def index
    @domains  = Connector.new().domains
  end
  
  def show
    @domain   = Domain.find(params[:id])
    @services = @domain.services
  end
  
  def locate
    @result  = Connector.locate(params[:query]||params[:search])  
    render :action => "locate", :layout => false
  end
end
