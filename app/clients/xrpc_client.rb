# frozen_string_literal: true

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

        if @http_method == :get
            # Delete any keys with nil values.
            kwargs.delete_if { |_, v| v.nil? }

            # Turn it into a query string.
            url.query = URI.encode_www_form(kwargs)
            request = Minigun::GET.new(url)
        else
            # Turn it into a POST body.
            request = Minigun::POST.new(url)
            unless kwargs.empty?
                # Set the body.
                request.json(kwargs)
            end
        end

        # Set the token if not nil.
        request.header('Authorization', "Bearer #{@token}") if @token

        # Send the request.
        response = request.run

        # Handle if it isn't 2xx.
        unless response.ok?
            # Try and parse the JSON.
            begin
                json = response.json
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
        unless response.body.empty?
            x = FastJsonparser.parse(response.body, symbolize_keys: false)
            return x
        end
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
