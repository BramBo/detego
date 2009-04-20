require 'config/spec_config'
require 'java'
require 'ftools'
require 'fileutils'

describe Service do
  before(:all) do
    @container  = Container.new
    @domain     = @container.add_domain(:test_domain)
    @service    = @domain.add_service(:test_service)
    
    # Move the example service into the newly created test service
    Dir.glob("test/spec/services/example/*").each do |f|
      if File.directory?(f)
        Dir.entries(f).reject{|e| e =~ /^\.+/}.each do |i|
          FileUtils.mkdir_p("contained/test_domain/test_service/#{f.gsub(/^.+?\/([^\/]+?)$/i, "\\1")}/", :mode => 0755)
          File.copy("#{f}/#{i}", "contained/test_domain/test_service/#{f.gsub(/^.+?\/([^\/]+?)$/i, "\\1")}/")        
        end
      else
        File.copy(f, "contained/test_domain/test_service")        
      end
    end
  end 
  
  it "should exist and have a domain as parent" do
    @service.class.should         eql(Service)
    @service.should               eql(@container.find(:test_domain).find(:test_service))

    @service.domain.class.should  eql(Domain)    
    @service.domain.should        eql(@domain)
    @service.domain.name.should   eql(:test_domain)
  end

  it "should have a name, fullname, path, ports, status and a directory set" do
    @service.name.should            eql(:test_service)
    @service.full_name.should       eql("#{@service.domain.name}::#{@service.name}")
    @service.port_in.should         eql($port_start-1)
    @service.port_out.should        eql($port_start)
    @service.status.should          eql("stopped")
    
    Dir["#{@service.path}"].should  eql ["#{@service.path}"]
  end
    
  # see /test/spec/services/example
  it "should be able to start and have an service manager available" do
    @service.start.should   eql(@service)
    @service.status.should  eql("Started")
  end
  
      it "should have it's own runtime environment after startup" do
        @service.runtime.class.should   eql(org.jruby.Ruby)
      end  
  
      it "should have an service manager in it's private scope" do
        @service.instance_variable_get("@service_manager").class.should   eql(DRbObject)
      end
    
      it "should have the correct meta-data" do
          @service.meta_data.class.should eql(ServiceMetaData)

          # hash is divided in 2 arrays
          service_methods = @service.meta_data.service_methods
          service_methods.class.should          eql Hash
          service_methods.keys.should           eql [:all, :exposed]

          # hash is divided in 3 arrays
          variables = @service.meta_data.exposed_variables
          variables.class.should                eql Hash
          variables.keys.should                 eql [:both, :read, :write]
        
          # Exposed values, represent the readable instance vars
          values = @service.meta_data.readable_var_values
          values.class.should                   eql Hash
        
          # this test is depenend on the implementation of the service
          # the installed service' ServiceManager is defined as follows:
          service_methods[:exposed].should      eql [["say_hello", []], ["set_status", ["str"]], ["get_status", []], ["sleep_test", []] ]
          service_methods[:all].should          eql []
          
          # and the attr accessor/readers/writers
          variables[:both].should               eql ["hello", "hello="]
          variables[:write].should              eql ["write_only="]
          variables[:read].should               eql ["read_only"]
          
          # Are our values correct?
          values.keys.should                    eql [:hello, :read_only]
          values[:hello].should                 eql "Hello world!"
          values[:read_only].should             eql "Can't be overwritten"
          
          # Alter for later test
          @service.runtime.runScriptlet(%{
            $service_manager.hello="Altered in test!"
          })
      end

  it "should be able to stop" do
    @service.shutdown.should  be_true
    @service.status.should    eql("stopped")    
  end
  
  it "should have persistant instance variables" do
    @service.start.should         eql(@service)
    @service.status.should        eql("Started")
    
    values = @service.meta_data.readable_var_values
    values.class.should           eql Hash   
    
    values[:hello].should         eql "Altered in test!"
    
    @service.shutdown.should      be_true
    @service.status.should        eql("stopped")    
  end
  
  after(:all) do  
     FileUtils.rm_rf "contained/test_domain"
  end
end