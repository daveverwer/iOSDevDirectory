require "json"
require "json-schema"
require "httparty"

task default: "validate:json"

namespace :validate do
  desc "Validate the JSON schema and the blogs JSON content"
  task :json do
    JSON::Validator.validate!("schema_blogs.json", "blogs.json")
  end

  desc "Ping each site and feed URLs and report any failures"
  task :ping do
    # The top level of the JSON file contains an array of languages
    languages = JSON.parse(File.read("blogs.json"))
    languages.each do |language|
      # Inside each language is an array of categories
      language["categories"].each do |category|
        # Inside each category is a list of sites 
        category["sites"].each do |site|
          site_url = URI(site["site_url"])
          feed_url = URI(site["feed_url"])
          ping_url(site_url)
          ping_url(feed_url)
        end
      end
    end
  end
end

def ping_url(url)
  begin
    response = HTTParty.head(url, follow_redirects: true)

    # Anything other than a 200 is classed as a faulure
    puts "#{response.code} for #{url}" unless response.code == 200
  rescue Net::OpenTimeout
    puts "Timeout for #{url}"
  rescue OpenSSL::SSL::SSLError
    puts "SSL Error for #{url}"
  rescue SocketError
    puts "Socket Error for #{url}"
  rescue => exception
    puts "#{exception.class} #{exception} for #{url}"
  end
end
