require 'google/cloud/translate'
require 'coreaudio'
require 'dotenv'
Dotenv.load('.env')

# Handle speech-to-text and translation from microphone input
class Streaming

  # Initializes class with new credentials and config
  # params => :speech, :credentials, :from, :to
  #
  # => @speech              a Google Cloud Speech instance
  # => @credentials         the Google Cloud Speech credentials
  # => @translate           a Google Cloud Translate instance
  # => @input_buffer        an audio buffer with a buffer size of 1024
  # => @streaming_config    configuration for the stream
  # => @DEFAULT             default language (EN)
  # => @user_language       source language
  # => @contact_language    target language
  def initialize(params = {})
    @speech = params[:speech]
    @credentials = params[:credentials]
    keyfile = ENV["TRANSLATION_CREDENTIALS"]
    creds = Google::Cloud::Translate::Credentials.new(keyfile)

    @translate = Google::Cloud::Translate.new(
      project_id: ENV["PROJECT_ID"],
      credentials: creds
    )

    input_device = CoreAudio.default_input_device
    @input_buffer = input_device.input_buffer(1024)

    @streaming_config =
      { config:
        {
          encoding: :LINEAR16,
          sample_rate_hertz: input_device.actual_rate,
          language_code: "en-US"
        },
        interim_results: true
      }
    @DEFAULT = "en"
    @user_language = params[:from] || @DEFAULT
    @contact_language = params[:to] || @DEFAULT
  end

  # Perform speech-to-text
  def stream
    stream = @speech.streaming_recognize(@streaming_config)
    @input_buffer.start

    while true
      break if stream.stopped?
      bits = @input_buffer.read(4096).to_a.map &:first # int array
      sample = bits.pack('s<*') # Convert to int-16 signed little-endian as String
      stream.send(sample)

      results = stream.results

      unless results.first.nil?
        alternatives = results.first.alternatives
        alternatives.each do |result|
          puts "Original: #{result.transcript}"
          puts "Translated: #{translate(result.transcript)}"
        end
        break
      end
    end

    @input_buffer.stop
    stream.stop
    stream.wait_until_complete!
  end

  # Perform translation
  def translate(text)
    translation = @translate.translate(text, from: @user_language, to: @contact_language)
    translation.text.gsub("&#39;", "'")
  end
end
