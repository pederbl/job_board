class List
  include Mongoid::Document

  def self.set(name, list)
    where(name: name).first.update_attributes(list: list)
  end

  def self.get(name)
    where(name: name).first.attributes["list"]
  end

end
