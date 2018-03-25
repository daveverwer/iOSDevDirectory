#!/usr/bin/env ruby

require "json-schema"

JSON::Validator.validate!("schema.json", "content.json")