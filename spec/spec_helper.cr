require "spec"
require "../src/api"

class TestApi2 < Api
  get do
    ok "text/plain", "byebye"
  end
end

class TestApi < Api
  get do
    ok "text/plain", "hello"
  end

  post "/test" do
  end

  mount TestApi2, "asd"
end

TestApi.print_routes

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
