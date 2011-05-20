class Isco

  def self.children
    return @children if defined? @children
    codes = I18n.t("isco_code").keys.map { |k| k.to_s }
    children = {}
    codes.each { |_code|
      if _code.length > 1
        node = children[_code[0..-2]] || []
        node << _code
        children[_code[0..-2]] = node
      end
    }
    return @children = children
  end

end
