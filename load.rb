require 'faraday'
require 'json'
require 'rugged'

# Connect to OpenSearch
conn = Faraday.new(url: 'http://localhost:9200')

# Open the current Git repository
repo = Rugged::Repository.new('.')

# Get a list of all code files in the repository
tree = repo.head.target.tree
files = tree.walk(:postorder) { |root, entry| root << entry if entry[:type] == :blob && entry[:name].match(/\.(rb|py|js)$/i) }.map(&:oid)

# Load each file into the OpenSearch index
files.each do |oid|
  # Get the contents of the file
  contents = repo.read(oid).data

  # Index the contents in OpenSearch
  response = conn.put do |req|
    req.url '/code/index'
    req.headers['Content-Type'] = 'application/json'
    req.body = JSON.generate({ content: contents })
  end

  # Print the response from OpenSearch
  puts response.body
end