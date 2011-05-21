module SalaryNormalizer

  def self.fix_currencies
    currencies = Value.get("currencies_to_euro")

    ids = JobOpening.where(deleted_at: nil).map { |d| d.id }
    ids.each_with_index { |id, idx|
      puts idx.to_s if idx.modulo(1000) == 0

      d = JobOpening.find(id).salary
      next if d.nil? or d.minimum.nil? or d.currency.nil? or d.period.nil?

      currency_factor = d.currency == "EUR" ? 1.0 : currencies[d.currency]
      unless currency_factor
        new_currency = case d.currency.downcase
        when "pound (sterling)"; "GBP"
        when "euro"; "EUR"
        when "czech koruna"; "CZK"
        when "swiss franc"; "CHF"
        when "norwegian krone"; "NOK"
        when "iceland krona"; "ISK"
        when "swedish krona"; "SEK"
        when "oth"; nil
        when "******"; nil
        else raise d.currency.inspect
        end
        d.update_attributes(currency: new_currency)
      end
    }
    nil
  end

  def self.normalize_salaries
    begin
      currencies = Value.get("currencies_to_euro")
  
      ids = JobOpening.where(deleted_at: nil).map(&:id)
      ids.each_with_index { |id, idx|
        puts idx.to_s if idx.modulo(1000) == 0
  
        d = JobOpening.find(id).salary
        if d.nil? or d.minimum.nil? or d.currency.nil? or d.period.nil?
          d.update_attribute(:normalized, nil) unless d.nil?
          next
        end
  
        currency_factor = d.currency == "EUR" ? 1.0 : currencies[d.currency]
        unless currency_factor
          if d.currency == "ISK"
            currency_factor = 0.005 # not reported by ECB
          else
            raise [id, d.currency].inspect unless currency_factor
          end
        end
  
        period_factor = case d.period
        when "Y"; 0.000516528926  # (12 months - 1 vacation) * 22 days * 8 hours
        when "M"; 0.00625         # (22 months - 2 vacation) * 8 hours
        when "W"; 0.025           # 40 hours
        when "D"; 0.125           # 8 hours
        when "H"; 1.0
        else raise d.period.inspect
        end
  
        d.update_attributes(normalized: (d.minimum * period_factor * currency_factor))
      }
    rescue => e
      HoptoadNotifier.notify(e)
      raise
    end
  end

  def self.update_highest_paid_jobs
    begin
      salary_spam_employers = [
        "EUPRO CHUR AG", 
        "Hagen Manfred Haustechnik",
        "FRANCK LOIRE M. FRANCK LOIRE",
        "HAYS Office Professionals",
        "HAYS",
        "Juergen Hemberle Personal Management SAS",
        "SOCIETE SELECTION PROFESSIONNELLE Mme BLEUSE BRIGITTE",
        "CONSEPT INGENIERIE Mme RECRUTEMENT RECRUTEMENT",
        "FINANCE M. MARTIN BORNE",
        "WUERTH ELEKTRONIK ITALIA S.R.L.",
        "GARDASEE TOURISMUS GMBH",
        "Hays Specialist Recruitment",
        "Sellbytel Group",
        "",
        "",
        ""
      ]
      list = JobOpening.where(deleted_at: nil, "salary.normalized".to_sym.ne => nil, "salary.normalized".to_sym.lt => 150, "employer.name".to_sym.ne => nil)
      list = list.not_in("employer.name" => salary_spam_employers)
      list = list.desc("salary.normalized")
      list = list.limit(10)
      ids = list.map(&:id)
      Value.set("highest_paid_jobs", ids)
    rescue => e
      HoptoadNotifier.notify(e)
      raise
    end
  end

end
