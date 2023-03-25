require 'json'
require 'json-schema'
require 'faraday'

task default: 'validate:json'

namespace :validate do
  desc 'Validate the JSON schema and the blogs JSON content'
  task :json do
    JSON::Validator.validate!('schema_blogs.json', 'blogs.json')
  end

  desc "Look for redirects in the site or feed URLs"
  task :redirects do
    file = File.read('blogs.json')
    data = JSON.parse(file)
    data.each do |language|
      language['categories'].each do |category|
        category['sites'].each do |site|
          %w[site_url feed_url].each do |field|
            response = Faraday.head(site[field])

            if response.status.between?(300, 399)
              new_uri = URI(response.headers['location'])

              # There are lots of incorrect redirects for YouTube channels.
              next if new_uri.host == 'consent.youtube.com'

              unless new_uri.is_a?(URI::HTTP) || new_uri.is_a?(URI::HTTPS)
                path = new_uri.path
                new_uri = URI(site[field])
                new_uri.path = path
              end

              puts "HTTP #{response.status} for #{site['title']}", site[field], new_uri, "\n"
              site[field] = new_uri.to_s
            end
          rescue Faraday::Error
            # Ignore connection errors and 404s
          end
        end
      end
    end

    File.write('new_blogs.json', JSON.pretty_generate(data))
  end
end
