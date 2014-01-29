#!/usr/bin/env ruby
require_relative 'util/registry'
require_relative 'util/commands'
require 'json'
require 'sshkit/dsl'

fail "Arguments: <server list> <image_id>" unless ARGV.length == 2
servers = ARGV[0].split(/[ ,;]+/)
image_id = ARGV[1]
image_name, image_version = image_id.match(/^(.*):(.*)$/).captures

class Container
  attr_reader :id, :image_id, :image_name, :image_tag
end

def get_container_ids(image_name)
  cmd = "docker ps -a | grep '#{image_name}:' | awk '{ print $1 }'"
  capture(cmd).split
end

def get_containers(image_name)
  return [] unless (container_ids = get_container_ids(image_name)).any?
  cmd = "docker inspect #{container_ids.join ' '}"
  puts cmd
  JSON.parse capture(cmd)
end

def start_container(image_id)
  cmd = "docker run -d #{image_id}"
  puts cmd
  capture(cmd)
end

def stop_containers(containers)
  running_containers = containers.select do |container| 
    container['State']['Running']
  end
  return if running_containers.none?
  running_container_ids = running_containers.map do |container|
    container['ID']
  end
  cmd = "docker stop #{running_container_ids.join ' '}"
  execute cmd
end

def remove_containers(containers)
  return if containers.none?
  container_ids = containers.map do |container|
    container['ID']
  end
  cmd = "docker rm #{container_ids.join ' '}"
  execute cmd
end

on servers, in: :parallel do
  old_containers = get_containers(image_name)
  new_container = start_container image_id
  puts new_container
  # notify load balancers?
  stop_containers old_containers
  remove_containers old_containers
end
