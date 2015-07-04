require 'http/parser'
require 'cgi'

module RDKit
  class HTTPResponder
    def run(cmd)
      [
        "HTTP/1.1 200 OK",
        "Date: #{CGI.rfc1123_date(Time.now)}",
        "Server: RDKit",
        "Content-Length: #{cmd.first.bytesize}",
        "Connection: Keep-Alive",
        "Content-Type: text/plain",
        "",
        cmd.first
      ].join("\r\n") + "\r\n"
    rescue StandardError => e
      e.message
    end

    def server
      Server.instance
    end
  end
end
