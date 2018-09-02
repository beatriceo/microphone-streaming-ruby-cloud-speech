require_relative 'streaming'
require 'google/cloud/speech'
require 'json'
require 'dotenv'
Dotenv.load('.env')


def get_credentials
  value = File.read(ENV["STREAMING_CREDENTIALS"])
  JSON.parse(value)
end

puts "Listening..."
credentials = get_credentials
speech = Google::Cloud::Speech.new
streaming = Streaming.new(speech: speech, credentials: credentials, from: "en", to: "fr")
while true
  streaming.stream
end
