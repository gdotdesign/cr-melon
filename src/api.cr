require "http"
require "json"
require "http/server"

class Api
  # This class will be the base for all routes
  abstract class Route
    @api : Nil | Api.class
    @method : String
    @path : String

    getter api, method, path

    def initialize(path, @method = nil, @api = nil)
      @path = path.sub(/^\//, "")
    end

    def match?(method : String, path : String)
      if api?
        path == @path
      else
        method == @method && path == @path
      end
    end

    def api?
      !@api.nil?
    end
  end

  # Contains routes for sub classes
  class Registry
    @@routes = {} of Api.class => Array(Route)

    def self.routes
      @@routes
    end
  end

  # Create an array of routes for every subclass
  Registry.routes[self] = [] of Route

  # Return routes for self
  def self.routes
    Registry.routes[self]
  end

  # Inherit routes
  macro inherited
    Registry.routes[{{@type}}] = Registry.routes[{{@type.superclass}}].dup
  end

  # Macro for mounting an api
  macro mount(api, path = "")
    # Create sub route to handle the given api
    class Api%id < Route
    end

    # Create route in registry
    Registry.routes[{{@type}}] << Api%id.new {{path}}, "", {{api}}

    # Match on the newly created route
    def handle_route(id : Api%id) HTTP::Server::Response
      {{api}}.new(@request, @response).route
    end
  end

  # Macro for creating a route
  macro route(method, path = "")
    # Create sub route to handle the given block
    class Route%id < Route
    end

    # Create route in registry
    Registry.routes[{{@type}}] << Route%id.new {{path}}, {{method.upcase}}, nil

    def handle_route(id : Route%id) : HTTP::Server::Response
      {{yield}}
      @response
    end
  end

  # Macro for post requests
  macro post(path = "")
    route "post", {{path}} do
      {{yield}}
    end
  end

  # Macro for get requests
  macro get(path = "")
    route "get", {{path}} do
      {{yield}}
    end
  end

  # Type definitions
  @request : HTTP::Request
  @response : HTTP::Server::Response

  # Initialize an api
  def initialize(@request, @response)
  end

  # Handle routing
  def route
    parts = (@request.path || "").split("/")
    parts.delete("")

    path = parts.shift { "" }
    path = path[1..-1] if path.starts_with?('/')

    method = @request.method.upcase

    current_route = routes.find do |route|
      route.match?(method, path)
    end

    if current_route
      @request.path = parts.join('/') if current_route.api?
      handle_route current_route
    else
      not_found
    end

    @response
  end

  def handle_route(route : Route)
    ok "text/plain", "Empty route found."
  end

  def routes
    Registry.routes[self.class]
  end

  def not_found
    @response.output.print "Not Found!"
    @response.status_code = 404
  end

  def ok(content_type, body, status = 200)
    @response.content_type = content_type
    @response.status_code = 200
    @response.output.print body
  end

  def json(object)
    ok "application/json", object.to_json
  end

  def self.listen(port)
    server = HTTP::Server.new(port) do |context|
      new(context.request, context.response).route
    end

    puts "Listening on http://0.0.0.0:8080"

    server.listen
  end

  def self.print_routes(indent = 0, last = false, calculate_last = false)
    fchar = last ? "" : "│"
    indentation = indent == 0 ? "" : fchar.ljust indent
    length = routes.size
    routes.each_with_index do |route, index|
      is_last = index == length - 1
      first_char = is_last ? "└" : "├"
      last = calculate_last ? is_last : last
      if route.api?
        puts indentation + first_char + " API  - /#{route.path} - #{route.api}"
        route.api.not_nil!.print_routes indent + 2, last
      else
        puts indentation + first_char + " #{route.method.ljust(4)} - /#{route.path}"
      end
    end
  end

  def self.print_route_table
    first_line = "API: #{name}"
    puts first_line
    puts "".ljust(first_line.size, '-')
    print_routes 0, false, true
  end
end
