require "json-schema"

task default: "validate"

desc "Validate the JSON schema and the content JSON"
task :validate do
  JSON::Validator.validate!("schema_blogs.json", "blogs.json")
end
