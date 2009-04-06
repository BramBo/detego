class DomainsController < ApplicationController
  def index
    @domains = Connector.new().domains
    flash[:notice] = "Welcome !"
  end
  
  def show
    @domain   = Domain.find(params[:id])
    @services = @domain.services
  end
end
