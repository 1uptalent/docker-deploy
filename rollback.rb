#!/usr/bin/env ruby
require_relative 'util/registry'

registry_uri = ENV['DOCKER_REGISTRY'] || 'localhost:9010'

fail "Arguments: <server list> <image_id>" unless ARGV.length == 2
servers = ARGV[0].split(/[ ,;]+/)
image_name = ARGV[1]
registry = Registry.new(registry_uri)

tags = registry.tags(image_name)
tags_by_version = tags.keys.group_by {|tag| tag[0..14] }
versions = tags_by_version.keys.sort
puts "All versions:\n\t#{versions.join "\n\t"}"

fail "No history to rollback, at least 2 images are needed" unless versions.length > 1

version_to_deploy, version_to_remove = versions.last(2)

puts "Version to deploy: #{version_to_deploy}"
puts "Version to remove: #{version_to_remove}"

tags_to_remove = tags_by_version[version_to_remove] || []
tags_to_remove.each do |tag|
  registry.remove_tag(image_name, tag)
end

tag_to_deploy = tags_by_version[version_to_deploy].first
cmd = "./deploy.rb #{servers.join(',')} #{registry.registry}/#{image_name}:#{tag_to_deploy}"
puts cmd
system(cmd, unsetenv_others: false )


