SitemapGenerator::Sitemap.default_host = "http://jobboteket.se"

SitemapGenerator::Sitemap.add_links do |sitemap|

  sitemap.add(job_openings_path)

  JobOpening.active.each_with_index { |job_opening, i| 
    sitemap.add(job_opening_path(id: job_opening.slug), priority: 1.0, changefreq: 'daily')
  }
  
end
