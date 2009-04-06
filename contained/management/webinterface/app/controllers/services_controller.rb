class ServicesController < ApplicationController
  def show
    @domain   = Domain.find(params[:domain_id])
    @service  = @domain.service(params[:id])
  end
end
