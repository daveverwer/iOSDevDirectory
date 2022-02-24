require "json"
require "json-schema"

task default: "validate:json"

namespace :validate do
  desc "Validate the JSON schema and the blogs JSON content"
  task :json do
    JSON::Validator.validate!("schema_blogs.json", "blogs.json")
  end
end
