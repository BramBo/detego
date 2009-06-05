require "#{Dir.getwd}/test/spec/config/spec_config"

describe Container do
  before(:all) do
    @container = Container.new
  end 
  
  it "should be able to add and remove domains" do
    @container.add_domain(:new_domain).should eql(@container.find(:new_domain))
    @container.remove(:new_domain).should be_true
  end
  
  it "should be able to add n domains and later find these" do
    h = {
      :domain_a => @container.add_domain(:domain_a), 
      :domain_b => @container.add_domain(:domain_b),
      :domain_c => @container.add_domain(:domain_c)
    }
    
    @container.find(:all).size.should eql(3)

    @container.find(:all).should == h
  end  
  
  it "should be able to delete all domains in one go" do
    h = {
      :domain_a => @container.find(:domain_a), 
      :domain_b => @container.find(:domain_b),
      :domain_c => @container.find(:domain_c)
    }
    
    @container.remove()
    @container.find(:all).size.should eql(0)
    @container.find(:all).should_not eql(h)
  end  
  
  it "should raise an exception when a false or no name is given for a domain" do
    lambda { @container.add_domain(nil) }       .should raise_error(Exception)
    lambda { @container.add_domain("asd  asd") }.should raise_error(Exception)
  end
  
  it "should not be able to add the same domain twice" do
    @container.add_domain(:new_domain).class.should eql(Domain)
    @container.add_domain(:new_domain).class.should eql(Domain)
    
    @container.find(:all).size.should == 1
  end
  
  it "Should make directories for each domain" do
    domain = @container.add_domain(:new_domain)
    Dir["#{SERVICES_PATH}/#{domain.name}"].should eql(["#{SERVICES_PATH}/#{domain.name}"])
  end
  
  it "Should delete the domain directory when deleting a domain" do
    domain = @container.add_domain(:new_domain)    
    @container.remove(:new_domain)
    Dir["#{SERVICES_PATH}/#{domain.name}"].should ==[]
  end
end
  