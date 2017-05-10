require "http"

module Melon
  class Handler
    include HTTP::Handler

    @api : Api.class

    def initialize(@api)
    end

    def call(context)
      @api.new(context.request, context.response).route
    end
  end
end
