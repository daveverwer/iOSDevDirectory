require "json"
require "json-schema"
require "httparty"
require "work_queue"

task default: "validate:json"

namespace :validate do
  desc "Validate the JSON schema and the blogs JSON content"
  task :json do
    JSON::Validator.validate!("schema_blogs.json", "blogs.json")
  end

  desc "Ping each site and feed URLs and report any failures"
  task :ping do
    wq = WorkQueue.new 30
    # The top level of the JSON file contains an array of languages
    urls = Array.new
    languages = JSON.parse(File.read("blogs.json"))
    languages.each do |language|
      # Inside each language is an array of categories
      language["categories"].each do |category|
        # Inside each category is a list of sites 
        category["sites"].each do |site|
          urls.push(URI(site["site_url"]))
          urls.push(URI(site["feed_url"]))
        end
      end
    end
    
    urls.each do |url|
      wq.enqueue_b do
        ping_url(url)
      end
    end
    
    wq.join
  end
end

def ping_url(url)
  begin
    response = HTTParty.head(url, follow_redirects: true, timeout: 10)
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
