require 'drb'    
require 'drb/acl'

require 'service_code_base.methods'

__rewire_standard_streams()
__setup_logging()

# initialize a default implementation of the ServiceManager
require 'service_code_base_initializer'
require 'service_manager.class.rb'

# Try to load initialize or (if it fails) service_manager
# |> If both fail, the service doesn't meet the requirements
__load_codebase_initialize()