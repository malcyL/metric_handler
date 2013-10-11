require 'net/http'
require 'uri'

module MetricHandler
  class MessagePoster
    def self.post(path, body, url)
      new(path, body, url).post
    end

    def initialize(path, body, url)
      @path = path
      @body = body
      @url  = url
    end

    def post
      return if @url.nil?

      http = Net::HTTP.new(@url, 80)
      headers = {"Content-Type" => "application/json" }
      response = http.post(@path, @body, headers)

      if response.code != '200'
        puts @path
        puts response
      end
    end
  end
end
