require "http"
require "json"
require "http/server"

class Api
  abstract class Route
    # @api : Nil | Api
    # @path : String
  end

  # Contains routes for sub classes
  class Registry
    @@routes = {} of Api.class => Hash(String, Route)

    def self.routes
      @@routes
    end
  end

  # Create a hash of routes for every subclass
  Registry.routes[self] = {} of String => Route

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
    Registry.routes[{{@type}}]["API:{{path.id}}"] = Api%id.new

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
    Registry.routes[{{@type}}]["{{method.id.upcase}}:{{path.id}}"] = Route%id.new

    def handle_route(id : Route%id) : HTTP::Server::Response
      {{yield}}
      @response
    end
  end

  # Macro for post requests
  macro post(path = "")
    route :post, {{path}} do
      {{yield}}
    end
  end

  # Macro for get requests
  macro get(path = "")
    route :get, {{path}} do
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
    if @request.path.nil?
      not_found
    else
      parts = @request.path.not_nil!.split("/")
      parts.delete("")

      path = parts.shift { "" }
      method = @request.method.upcase

      if routes.has_key?("API:#{path}")
        @request.path = parts.join('/')
        handle_route routes["API:#{path}"]
      elsif routes.has_key?("#{method}:#{path}")
        handle_route routes["#{method}:#{path}"]
      else
        not_found
      end
    end

    @response
  end

  def handle_route(route : Route)
    ok "text/plain", "Empty route found."
  end

  def routes
    Registry.routes[self.class]
  end

  def self.listen(port)
    server = HTTP::Server.new(port) do |context|
      new(context.request, context.response).route
    end

    puts "Listening on http://0.0.0.0:8080"

    server.listen
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

  def self.print_routes
    puts name
    routes.map do |key, route|
      method, path = key.not_nil!.split(':')
      puts "- #{method} #{path}"
    end
  end
end
