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
    where(name: name).first.attributes["value"] rescue raise(name)
  end

end
