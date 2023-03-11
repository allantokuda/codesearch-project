require 'faraday'
require 'json'
require 'rugged'

# Connect to OpenSearch
conn = Faraday.new(url: 'https://localhost:9200', ssl: { verify: false }) do |f|
  f.request :authorization, :basic, 'admin', 'admin'
end

path = ARGV[0]
raise 'Must specify path to Git repository.' unless path

# Open the current Git repository
repo = Rugged::Repository.new(path)

# Get a list of all code files in the repository
tree = repo.head.target.tree
oids = tree.walk(:postorder).select { |root, entry| entry[:type] == :blob && entry[:name].match(/\.(rb|py|js)$/i) }.map { |root, entry| entry[:oid] }

# Load each file into the OpenSearch index
oids.each do |oid|
  # Get the contents of the file
  contents = repo.read(oid).data

  # Index the contents in OpenSearch
  response = conn.put("/code/_doc/#{oid}") do |req|
    req.headers['Content-Type'] = 'application/json'
    req.body = JSON.generate({ content: contents })
  end

  # Print the response from OpenSearch
  puts response.body
end