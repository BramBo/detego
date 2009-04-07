class DomainsController < ApplicationController
  def index
    @domains = Connector.new().domains
  end
  
  def show
    @domain   = Domain.find(params[:id])
    @services = @domain.services
  end
end
