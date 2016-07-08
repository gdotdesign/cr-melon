module Melon
  extend self

  def print_routes(api, indent = 0, last = false, calculate_last = false)
    fchar = last ? "" : "│"
    indentation = indent == 0 ? "" : fchar.ljust indent
    length = api.routes.size
    api.routes.each_with_index do |route, index|
      is_last = index == length - 1
      first_char = is_last ? "└" : "├"
      last = calculate_last ? is_last : last
      if route.api?
        puts indentation + first_char + " API  - /#{route.path} - #{route.api}"
        print_routes route.api.not_nil!, indent + 2, last
      else
        puts indentation + first_char + " #{route.method.ljust(4)} - /#{route.path}"
      end
    end
  end

  def print_route_table(api)
    first_line = "API: #{api.name}"
    puts first_line
    puts "".ljust(first_line.size, '-')
    print_routes api, 0, false, true
  end

  def listen(port)
    server = HTTP::Server.new(port) do |context|
      new(context.request, context.response).route
    end

    puts "Listening on http://0.0.0.0:8080"

    server.listen
  end
end
