require "./melon/router_printer"
require "./melon/api"

module Melon
  extend self

  def print_routes(api)
    RoutePrinter.new.print api
  end

  def listen(api, port)
    server = HTTP::Server.new(port) do |context|
      api.new(context.request, context.response).route
    end

    puts "\nListening on http://0.0.0.0:#{port}"

    server.listen
  end
end
