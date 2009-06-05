require "#{Dir.getwd}/test/spec/config/spec_config"

describe Domain do
  before(:all) do
    @container = Container.new
    @domain    = @container.add_domain(:test_domain)
  end 

  it "should have no services at start" do
    @domain.find(:all).size.should == 0
  end
  
  it "should be able to add a new service and have a service directory" do
    @domain.add_service(:new_service).class.should eql(Service)
    @domain.find(:all).size.should == 1
    
    Dir["#{SERVICES_PATH}/#{@domain.name}/new_service"].should eql ["#{SERVICES_PATH}/#{@domain.name}/new_service"]
  end
  
  it "should be able to delete a service" do
    @domain.remove(:new_service).should be_true
    Dir["#{SERVICES_PATH}/#{@domain.name}/new_service"].should eql []
  end
  
  it "should not be able to add the same service twice" do
    @domain.add_service(:new_service).class.should eql(Service)
    @domain.add_service(:new_service).class.should eql(Service)
      
    @domain.find(:all).size.should == 1
  end
  
  it "should raise an exception when a false or no name is given for a service" do
    lambda { @domain.add_service(nil) }       .should raise_error(Exception)
    lambda { @domain.add_service("asd  asd") }.should raise_error(Exception)
  end
  
  after(:all) do
    @domain.remove(:new_service)
    @container.remove(:test_domain)
  end
end