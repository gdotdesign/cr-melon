require "spec"
require "../src/melon/api"
require "../src/melon"

class TestApi2 < Melon::Api
  description "Mounted API"

  get description: "hello" do
    ok "text/plain", "byebye"
  end

  mount TestApi3, "test"
end

class TestApi3 < Melon::Api
  description "WTF"

  post description: "Prints WTF" do
    ok "text/plain", "wtf"
  end
end

class TestApi < Melon::Api
  description "My Awesome API"

  get description: "Greets you" do
    ok "text/plain", "hello"
  end

  get "/test", description: "It just works" do
    ok "text/plain", "works"
  end

  post "test" do
  end

  mount TestApi2, "asd"
end

Melon.print_routes TestApi

def mock_request(method, path, body)
  request = HTTP::Request.new(
    method,
    path,
    body: body
  )

  io = MemoryIO.new

  response = HTTP::Server::Response.new io

  TestApi.new(request, response).route

  response.close
  io.rewind

  resp = HTTP::Client::Response.from_io io
  resp
end
