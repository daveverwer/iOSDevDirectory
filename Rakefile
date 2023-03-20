require 'json'
require 'json-schema'
require 'net/https'

task default: 'validate:json'

namespace :validate do
  desc 'Validate the JSON schema and the blogs JSON content'
  task :json do
    JSON::Validator.validate!('schema_blogs.json', 'blogs.json')
  end

  task :urls do
    file = File.read('blogs.json')
    data = JSON.parse(file)
    data.each do |language|
      language['categories'].each do |category|
        category['sites'].each do |site|
          %w[site_url feed_url].each do |field|
            begin
              res = Net::HTTP.get_response(URI(site[field]))

              if res.code.to_i == 301 || res.code.to_i == 302
                puts "#{site['title']} returns a #{res.code} for #{field} (#{site[field]})"
                if !res['location'].start_with?('http://') && !res['location'].start_with?('https://')
                  puts "Redirect is not a valid URL (#{res['location']}), skipping"
                  puts
                  next
                end

                site[field] = res['location']
                puts "Updating #{field} to #{site[field]}"
                puts
              elsif res.code.to_i >= 400
                # NO OP
                # puts "#{site['title']} returns a #{res.code} for #{field} (#{site[field]})"
                # puts
              end
            rescue
              # NO OP
              # puts "#{site['title']} is unable to connect for #{field} (#{site[field]})"
              # puts
            end
          end
        end
      end
    end
    File.open('new_blogs.json', 'w') do |f|
      f.write(JSON.pretty_generate(data))
    end
  end
end
