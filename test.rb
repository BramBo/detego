require 'java'
include_class('org.jruby.Ruby') {|pkg, name| "JJRuby" }

instA = JJRuby.newInstance() #Should be current

require 'drb'
$a = "booted"
class ServiceProvider
  def initialize
    
  end

  def bbs_call
    $a = "called "
    return "HALLO"
  end
end

DRb.start_service 'druby://127.0.0.1:6666', ServiceProvider.new



instA.evalScriptlet %{
  require 'java'
  require 'drb'
  DRb.start_service

  obj = DRbObject.new(nil, 'druby://127.0.0.1:6666')
  p obj.bbs_call
}

p $a

# instA = org.jruby.Ruby.newInstance() #Should be current
# instB = org.jruby.Ruby.newInstance()
# 
# p Marshal.dump(instA)
# 
# no marshal_dump is defined for class Java::JavaObject
# # 
#  out = java.io.ByteArrayOutputStream.new()
#  m = org.jruby.runtime.marshal.MarshalStream.new(instA, out, -1)
# # 
# # 
 # p m.dumpObject(instB.getTopSelf)

# require 'java'
# 
# @runtime  = org.jruby.Ruby.newInstance()
# @runtime.evalScriptlet(%"
#     def 
#     p h=Marshal.load('#{data}')
# ")
# 
# class A 
#   def initialize(str)
#     @str = str
#   end
#   def print
#     if 2 > 1
#       p ""+str
#     end
#   end
# end
# 
# a = {:dude => "ok", :ok => "Okay!"}
# data = Marshal.dump(a, limit=-1)
# 
# 
# @runtime.evalScriptlet(%"
#     p h=Marshal.load('#{data}')
# ")  