require 'http/parser'

module RDKit
  class HTTPParser
    def initialize
      @parser = HTTP::Parser.new

      @responses = []

      # https://github.com/tmm1/http_parser.rb

      @body = nil

      @parser.on_message_begin = proc do
      end

      @parser.on_headers_complete = proc do
        # p @parser.http_method
        # p @parser.request_url
        # p @parser.headers

        if (length = @parser.headers['Content-Length']) && length.to_i > 0
          @body = ''
        else
          @responses << ['OK']
        end
      end

      @parser.on_body = proc do |chunk|
        @body << chunk
      end

      @parser.on_message_complete = proc do
        # Headers and body is all parsed
        if @body
          @responses << [@body]

          @body = nil
        end
      end
    end

    def feed(data)
      @parser << data
    end

    def gets
      if result = @responses.shift

        result
      else
        false
      end
    end
  end
end
