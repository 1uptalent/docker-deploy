def local_tags(registry, image)
  repository_name = "#{registry.registry}/#{image}"
  cmd = %{docker-custom images --no-trunc | grep #{repository_name} | awk '{ print $2 "," $3 }'}

  puts "Listing local tags\n\t#{cmd}"
  lines = `#{cmd}`.split
  tags = {}
  lines.each do |line|
    name, image_id = line.split ","
    tags[name] = image_id
  end
  tags
end

def run_command(cmd)
  puts "\t#{cmd}"
  puts "[[PARANOID]] Press enter to continue. Ctrl+C to abort" ; STDIN.gets # REMOVE
  system(cmd) || puts("\tCommand failed") || exit(false)
end

def docker_pull(registry, image)
  run_command "docker-custom pull #{registry.registry}/#{image}"
end

def docker_rmi(image_ids)
  run_command "docker-custom rmi #{image_ids.join ' '}"
end

def docker_push(registry, image)
  run_command "docker-custom push #{registry.registry}/#{image}"
end
