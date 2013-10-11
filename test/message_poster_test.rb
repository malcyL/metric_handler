require_relative 'test_helper'

module MetricHandler
  class MessagePosterTest < Minitest::Test

    def setup_handler( options = {} )
      @path = options.fetch(:path, 'somepath')
      @body = options.fetch(:body, 'some body')
      @url = options.fetch(:url, 'meducation.net')
      @handler = MessagePoster.new(@path, @body, @url)
    end

    def test_it_creates
      setup_handler
      refute @handler.nil?
    end

    def test_it_does_nothing_if_url_nil
      setup_handler(url: nil)
      Net::HTTP.expects(:new).never
      @handler.post
    end

    def test_path_body_headers_in_post
      setup_handler
      headers = {"Content-Type" => "application/json" }
      Net::HTTP.any_instance.expects(:post)
               .with(@path, @body, headers)
               .returns(mock(code: '200'))
      @handler.post
    end

    def test_url_in_post
      setup_handler
      http = mock(post: mock(code: '200'))
      Net::HTTP.expects(:new).with(@url, 80).returns(http)
      @handler.post
    end

    def test_sucessful_should_have_no_output
      assert_output("") {
        setup_handler
        http = mock(post: mock(code: '200'))
        Net::HTTP.expects(:new).with(@url, 80).returns(http)
        @handler.post
      }
    end

    def test_failed_should_have_output
      assert_output("somepath\nServer Error\n") {
        setup_handler
        http = mock(post: mock(code: '500', to_s: 'Server Error'))
        Net::HTTP.expects(:new).with(@url, 80).returns(http)
        @handler.post
      }
    end
  end
end
