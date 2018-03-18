require 'twitter'
require 'faraday'

VOICE_WAV_FILE_PATH = 'tmp/voice.wav'.freeze

@stream_client = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
  config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
  config.access_token        = ENV['TWITTER_OAUTH_TOKEN']
  config.access_token_secret = ENV['TWITTER_OAUTH_TOKEN_SECRET']
end

@conn = Faraday.new(:url => 'https://api.voicetext.jp') do |faraday|
  faraday.request  :url_encoded
  faraday.adapter  Faraday.default_adapter
  faraday.basic_auth(ENV['VOICETEXT_BASIC_USER'], '')
end


def download_voice(text)
  response = @conn.post '/v1/tts', { text: normalize(text), speaker: 'show' }
  File.open(VOICE_WAV_FILE_PATH, 'wb') { |fp| fp.write(response.body) }
end

def normalize(text)
  text.
    gsub(/RT @\w*: /, '').
    gsub(/https?:\/\/[\w\/:%#\$&\?\(\)~\.=\+\-]+/, '')
end


@stream_client.user do |object|
  if object.is_a?(Twitter::Tweet)
    puts "[#{object.created_at}] #{object.user.name}(@#{object.user.screen_name}): #{object.text}"

    download_voice(object.text)
    %x{ afplay #{VOICE_WAV_FILE_PATH} }
  end
end