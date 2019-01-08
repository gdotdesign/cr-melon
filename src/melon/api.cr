require "http"
require "json"
require "http/server"

module Melon
  class Api
    # This class will be the base for all routes
    abstract class Route
      @api : Nil | Api.class
      @method : String
      @path : String
      @resource : Bool
      @description : String

      getter api, method, path, description, resource

      def initialize(path, @method = nil, @api = nil, @description = "", @resource = false)
        @path = path.sub(/^\//, "")
      end

      def match?(method : String, path : String)
        if @resource
          true
        elsif api?
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
      @@descriptions = {} of Api.class => String

      def self.routes
        @@routes
      end

      def self.descriptions
        @@descriptions
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
        {{api}}.new(@request, @response, params).route
      end
    end

    macro resource(name)
      class Resource%id < Api
        {{yield}}
      end

      class Route%id < Route
      end

      Registry.routes[{{@type}}] << Route%id.new "{{name.id}}", "", Resource%id, "", true

      def handle_route(id : Route%id) : HTTP::Server::Response
        params = @params.merge({ {{name}} => @part })
        Resource%id.new(@request, @response, params).route
      end
    end

    # Macro for creating a route
    macro route(method, path = "", description = "")
      # Create sub route to handle the given block
      class Route%id < Route
      end

      # Create route in registry
      Registry.routes[{{@type}}] << Route%id.new {{path}}, {{method.upcase}}, nil, {{description}}

      def handle_route(id : Route%id) : HTTP::Server::Response
        {{yield}}
        @response
      end
    end

    # Macro for post requests
    macro post(path = "", description = "")
      route "post", {{path}}, {{description}} do
        {{yield}}
      end
    end

    # Macro for get requests
    macro get(path = "", description = "")
      route "get", {{path}}, {{description}} do
        {{yield}}
      end
    end

    # Type definitions
    @request : HTTP::Request
    @response : HTTP::Server::Response
    @part : String = ""

    getter params, part

    macro description(desc)
      Registry.descriptions[self] = {{desc}}
    end

    def self.description
      return "" unless Registry.descriptions.has_key?(self)
      Registry.descriptions[self]
    end

    # Initialize an api
    def initialize(@request, @response, @params = {} of Symbol => String)
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
        @part = path
        handle_route current_route
      else
        not_found
      end

      @response
    end

    def handle_route(route : Route)
      ok "text/plain; charset=utf-8", "Empty route found."
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
      ok "application/json; charset=utf-8", object.to_json
    end
  end
end
