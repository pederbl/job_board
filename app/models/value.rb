class Value
  include Mongoid::Document

  def self.set(name, value)
    d = where(name: name).first
    if d
      d.update_attributes(value: value)
    else
      create(name: name, value: value)
    end
  end

  def self.get(name)
    d = where(name: name).first
    return nil unless d
    d.attributes["value"] 
  end

end
