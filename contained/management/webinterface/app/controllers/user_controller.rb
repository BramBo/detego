class UserController < ApplicationController
  def index
    @status = {:before => "", :after =>""}
    @meta   = $provider.for(:root, :service_a).get_meta_data
    
    # get the current status, Set the status and get the status again
    @status[:before] = $provider.on(:root, :service_a).get_status
    $provider.on(:root, :service_a).set_status("#{$service[:full_name]} infiltrated :root::service_a! @ #{Time.now}")
    @status[:after] = $provider.on(:root, :service_a).get_status
    
    # meta data
    @meta[:exposed_methods]
    @meta[:exposed_variables][:both]
    @meta[:exposed_variables][:write]
    @meta[:exposed_variables][:read]
  end
end
