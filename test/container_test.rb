require 'rspec'

describe Container do
  it "should have test_domain" do
    container = Container.new
    container.add_domain :test_domain
    container.should 
  end
  
end