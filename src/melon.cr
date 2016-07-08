require "./melon/router_printer.cr"

module Melon
  extend self

  def print_route_table(api)
    RoutePrinter.new.print api
  end

  def listen(port)
    server = HTTP::Server.new(port) do |context|
      new(context.request, context.response).route
    end

    puts "Listening on http://0.0.0.0:8080"

    server.listen
  end
end
