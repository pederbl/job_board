module ECB
  
  class Client
    def self.sync_currency_rates
      require "rexml/document"
      url = "http://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml"
      result = RestClient.get url, {:accept => :xml}
      hash = Hash.from_xml(result)["Envelope"]["Cube"]["Cube"]["Cube"]
      currencies = hash.inject({}) { |currencies, h| currencies[h["currency"]] = (1.0 / h["rate"].to_f); currencies }
      alue.set("currencies_to_euro", currencies)
    end
  end

end
