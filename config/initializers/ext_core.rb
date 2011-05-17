class Object

  def nil_if_blank
    self.blank? ? nil : self
  end

end


