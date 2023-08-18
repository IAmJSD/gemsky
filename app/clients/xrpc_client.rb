# frozen_string_literal: true

require 'net/http'

class BlueskyError < StandardError
    def initialize(error, message, status_code)
        super("#{error}: #{message}")
        @error = error
        @message = message
        @status_code = status_code
    end

    attr_reader :error, :message, :status_code
end

class XrpcRequestor
    def initialize(url, token, method)
        @url = url
        @token = token
        @http_method = method
    end

    def method_missing(method, **kwargs)
        method = method.to_s.gsub('_', '.')

        url = URI.parse(@url)
        url.path = "/xrpc/#{method}"

        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = url.scheme == 'https'

        if @http_method == :get
            # Turn it into a query string.
            url.query = URI.encode_www_form(kwargs)
            request = Net::HTTP::Get.new(url)
        else
            # Turn it into a POST body.
            request = Net::HTTP::Post.new(url)
            unless kwargs.empty?
                # Turn the body into JSON.
                request.body = kwargs.to_json

                # Set the content type.
                request['Content-Type'] = 'application/json'
            end
        end

        # Set the token if not nil.
        request['Authorization'] = "Bearer #{@token}" if @token

        # Send the request.
        response = http.request(request)

        # Handle if it isn't 2xx.
        unless response.is_a?(Net::HTTPSuccess)
            # Try and parse the JSON.
            begin
                json = JSON.parse(response.body)
            rescue
                json = {
                    'error' => 'ServerDidntReturnJson',
                    'message' => "#{response.code}: #{response.body}",
                }
            end

            # Raise the error.
            raise BlueskyError.new(json['error'], json['message'], response.code.to_i)
        end

        # Parse the JSON.
        JSON.parse(response.body)
    end
end

class XrpcClient
    def initialize(url, token=nil)
        @url = url
        @token = token
    end

    def get
        XrpcRequestor.new(@url, @token, :get)
    end

    def post
        XrpcRequestor.new(@url, @token, :post)
    end
end
