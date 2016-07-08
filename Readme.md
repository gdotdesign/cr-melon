# Melon
Class based Http APIs in crystal

## Description
This is a proof of concept of creating a shard that allows people to create
APIs with **classes** with the following fetaures:
- Inherit form an other API
- Mounting other APIs at an endpoint
- Introspactable routes and APIS

Example:
```crystal
require "../src/melon"

USERS = [
  {name: "John Doe"},
  {name: "Someone Else"},
]

class Users < Melon::Api
  description "Users Endpoint"

  get description: "Get all users" do
    json USERS
  end
end

class Root < Melon::Api
  description "My Awesome API"

  get description: "Simple GET request." do
    ok "text/plain", "Hello there!"
  end

  post do
    ok "text/plain", "You have posted something."
  end

  mount Users, "users"
end

Melon.print_routes Root
Melon.listen Root, 8080

# Root - My Awesome API
# ----------------------------------------
# ├─ GET - /         # Simple GET request.
# ├─ POST - /
# └─┬─ API - /users  # Users Endpoint
#   └─ GET - /       # Get all users
# ----------------------------------------
# Listening on http://0.0.0.0:8080
```
