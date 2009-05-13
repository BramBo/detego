class Valutas
  MAP = {
      :eur => {:dol => 0.8},
      :dol => {:eur => 1.4}
  }
  
  def self.calc(from, to, amount)
    puts "Converting #{from}(#{amount}) => #{to}"
    rate = MAP[from.to_s.downcase.to_sym][to.to_s.downcase.to_sym]
    return amount.to_f * rate.to_f
  end
end