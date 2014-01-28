#!/usr/bin/env ruby
require 'net/http'
require 'json'
require 'fileutils'
require 'time'
require_relative 'util/registry'
require_relative 'util/commands'

def sync_local_tags(registry, image, registry_tag_names, local_tag_names)
  only_on_registry = registry_tag_names - local_tag_names
  if only_on_registry.any?
    puts "Pulling the repository beacuse some tags from the registry not locally present: #{only_on_registry.inspect}"
    docker_pull registry, image
    return true
  end
  return false
end

def sync_remote_tags(registry, image, registry_tag_names, local_tag_names)
  only_local = local_tag_names - registry_tag_names
  if only_local.any?
    puts "Removing local keys not found on the registry: #{only_local.inspect}"
    docker_rmi only_local.map {|tag| "#{registry.registry}/#{image}:#{tag}"}
    return true
  end
  return false
end

def sync_tags(registry, image)
  registry_tag_names = registry.tags(image).keys
  local_tag_names = local_tags(registry, image).keys
  puts "Registry: #{registry_tag_names.inspect}"
  puts "Local:    #{local_tag_names.inspect}"
  tags_updated = sync_local_tags(registry, image, registry_tag_names, local_tag_names)
  tags_updated ||= sync_remote_tags(registry, image, registry_tag_names, local_tag_names)
  if tags_updated
    puts "Tags were modified, resyncing to ensure they match"
    sync_tags(registry, image)
  end
end

def clone_project(project_repo, branch)
  directory = "work_dir/clean-copy"
  FileUtils::rm_r directory, force: true
  FileUtils::mkdir_p directory
  puts "Cloning #{branch} into #{directory}"
  run_command("git clone --depth 1 --single-branch --branch #{branch} #{project_repo} #{directory}")
end

def build_image(registry, image)
  directory = "work_dir/clean-copy"
  repository_name = "#{registry.registry}/#{image}"
  puts "Calculating build id"
  commit_date, hash, author = `cd #{directory} && git log -n1 --format="%ci;%h;%ae"`.split(/[;@]/)
  formatted_date = Time.parse(commit_date).utc.strftime('%Y%m%d_%H%M%S')
  build_id = "#{formatted_date}_#{hash}_#{author}"
  puts "build_id = #{build_id}"
  full_tag = "#{repository_name}:#{build_id}"
  puts "cleaning up files not used on production"
  %w{.git test spec features}.each do |unused|
    path = "#{directory}/#{unused}"
    next unless File.exists? path
    puts "\t#{path}"
    FileUtils.rm_r path, force: true
  end
  puts "Building Dockerfile with tag: #{full_tag}"
  run_command "docker-custom build -rm -t #{full_tag} #{directory}"
end

registry_uri = ENV['DOCKER_REGISTRY'] || 'localhost:9010'
fail("Need the git project uri: git@github.com:amuino/rails-deploy-with-docker.git") unless ARGV[0]
github_repo, branch = (ARGV[0]+'#master').split("#")
repository_name = ARGV[1] || github_repo.split("/").last.split('.').first

registry = Registry.new(registry_uri)

# LOCAL part
sync_tags(registry, repository_name)
clone_project(github_repo, branch)
build_image(registry, repository_name)
docker_push(registry, repository_name)

# REMOTE



