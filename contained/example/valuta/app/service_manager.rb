class ServiceManager
  exposed_methods :convert
  def start()
    self.status = "Started !"
  end
  
  has_parameters [:from, :to, :amount]
  def convert(from,to,amount)
    Valutas.calc(from,to,amount)
  end
end