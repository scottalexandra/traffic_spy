require_relative 'test_helper'
require 'minitest/pride'

module TrafficSpy

  class ServerTest < Minitest::Test
    include Rack::Test::Methods

    def app
      Server
    end

    def teardown
      DB[:identifiers].delete
    end

    def test_post_sources_for_missing_parameters
      post '/sources', 'identifier=hotmail'
      assert_equal 400, last_response.status
    end

    def test_post_sources_for_identifier_already_exists
      post '/sources', 'identifier=jumpstartlab&rootUrl=http://jumpstartlab.com'
      post '/sources', 'identifier=google&rootUrl=http://google.com'
      assert_equal 200, last_response.status

      post '/sources', 'identifier=jumpstartlab&rootUrl=http://jumpstartlab.com'
      assert_equal 403, last_response.status
    end

    def test_post_sources_for_success
      post '/sources', 'identifier=turing&rootUrl=http://turing.com'
      assert_equal 200, last_response.status
      assert_equal "Success {\"identifier\":\"turing\"}\n", last_response.body
    end

    def test_post_sources_identifier_has_a_missing_payload
      post '/sources/jumpstartlab/data', '" " http://localhost:9393/sources/jumpstartlab/data'
      assert_equal 400, last_response.status
      assert_equal "Missing Payload", last_response.body
    end

    def test_post_sources_identifier_not_registered
      post '/sources/as/data','payload={}'
      assert_equal 403, last_response.status
      assert_equal "Application Not Registered", last_response.body
    end

    def test_post_sources_identifier_for_success
      post '/sources', 'identifier=jumpstartlab&rootUrl=http://jumpstartlab.com'
      post '/sources/jumpstartlab/data',
           "payload={\"url\":\"http://jumpstartlab.com/blog\",
           \"requestedAt\":\"2013-02-16 21:38:28 -0700\",\"respondedIn\":37,
           \"referredBy\":\"http://jumpstartlab.com\",\"requestType\":\"GET\",
           \"parameters\":[],\"eventName\": \"socialLogin\",
           \"userAgent\":\"Mozilla/5.0 (Macintosh%3B Intel Mac OS X 10_8_2)
           AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1309.0 Safari/537.17\",
           \"resolutionWidth\":\"1920\",\"resolutionHeight\":\"1280\",
           \"ip\":\"63.29.38.211\"}"
      assert_equal 200, last_response.status
    end
  end
end