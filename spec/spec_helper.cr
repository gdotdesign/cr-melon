require "spec"
require "../src/api"

class TestApi2 < Api
  get do
    ok "text/plain", "byebye"
  end

  mount TestApi3, "test"
end

class TestApi3 < Api
  post do
    ok "text/plain", "wtf"
  end
end

class TestApi < Api
  get do
    ok "text/plain", "hello"
  end

  get "/test" do
    ok "text/plain", "works"
  end

  post "test" do
  end

  mount TestApi2, "asd"
  mount TestApi2, "bsg"
  mount TestApi3, "xxx"
  mount TestApi2, "asd"
end

TestApi.print_route_table

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
