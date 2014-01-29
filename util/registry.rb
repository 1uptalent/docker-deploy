require 'net/http'
require 'json'

class Registry
  attr_reader :registry, :registry_url

  def initialize(registry_uri)
    @registry = registry_uri
    @registry_url = "http://#{registry}"
  end

  def tags(repository_name)
    list_tags_url = "#{@registry_url}/v1/repositories/#{repository_name}/tags"
    response = Net::HTTP.get_response(URI(list_tags_url))
    if response.code == '404'
      puts "Repository not found. First build?"
      return {}
    end
    json = JSON.parse(response.body)
    raise "Request error: #{json["error"]} | #{list_tags_url}" if json["error"]
    return json
  end

  def remove_tag(repository_name, tag)
    remove_tag_url = "#{@registry_url}/v1/repositories/#{repository_name}/tags/#{tag}"
    uri = URI(remove_tag_url)
    response = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => uri.scheme == 'https') do |http|
      http.delete(remove_tag_url)
    end
    return response == Net::HTTPSuccess
  end

  def add_tag(repository_name, tag, image_id)
    add_tag_url = "#{@registry_url}/v1/repositories/#{repository_name}/tags/#{tag}"
    response = Net::HTTP.put(URI(add_tag_url), image_id)
    json = JSON.parse(response)
    return json
  end
end
