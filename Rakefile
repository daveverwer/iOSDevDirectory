require 'json'
require 'json-schema'
require 'net/https'

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
            response = Net::HTTP.get_response(URI(site[field]))

            if response.code.to_i == 301 || response.code.to_i == 302
              puts "#{site['title']} returns a #{response.code} for #{field} (#{site[field]})"

              if !response['location'].start_with?('http://') && !response['location'].start_with?('https://')
                puts "Redirect is not a valid URL (#{response['location']}), skipping"
                puts
                next
              end

              site[field] = response['location']
              puts "Updating #{field} to #{site[field]}"
              puts
            elsif response.code.to_i >= 400
              # NO OP
              # puts "#{site['title']} returns a #{response.code} for #{field} (#{site[field]})"
              # puts
            end
          rescue StandardError
            # NO OP
            # puts "#{site['title']} is unable to connect for #{field} (#{site[field]})"
            # puts
          end
        end
      end
    end

    File.open('new_blogs.json', 'w') do |f|
      f.write(JSON.pretty_generate(data))
    end
  end
end
