require 'http/parser'
require 'cgi'
require 'rack'
require 'stringio'

module RDKit
  class HTTPResponder
    def run(cmd)
      method, path = cmd.first.split('|')

      status, headers, body = case method
      when 'get'
        if @@endpoints_get[path]
          status, headers, body = @@endpoints_get[path].call

          [status, headers.merge(default_headers), body]
        else
          error_404
        end
      else
        error_404
      end

      response = Rack::Response.new(body, status, headers)

      status, headers, body = response.finish

      out = StringIO.new

      out.print "HTTP/1.1: #{status} #{Rack::Utils::HTTP_STATUS_CODES[status]}\r\n"

      headers.each do |k, vs|
        vs.split("\n").each { |v| out.print "#{k}: #{v}\r\n"; }
      end
      out.print "\r\n"
      out.flush

      body.each do |part|
        out.print part; out.flush
      end

      out.string
    end

    def server
      Server.instance
    end

    private

    def error_400
      [400, default_headers, []]
    end

    def error_404
      [404, default_headers, ['Not Found']]
    end

    def default_headers
      {
        "Date"         => CGI.rfc1123_date(Time.now),
        "Server"       => "RDKit",
        "Connection"   => "Keep-Alive",
        "Content-Type" => "text/plain"
      }
    end

    def self.get(path, &block)
      @@endpoints_get ||= {}

      @@endpoints_get[path] = block
    end
  end
end
