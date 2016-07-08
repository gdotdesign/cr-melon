# Melon
Class based Http APIs in crystal

## Description
This is a proof of concept of creating a shard that allows people to create
APIs with **classes** with the following fetaures:
- DSL for building the APIs (get, put, post, etc...)
- Inherit form an other APIs
- Mounting other APIs at an endpoint
- Inspectable routes and APIs for documentation

[Example](examples/simple.cr):
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

## Explanation
This implementation is heavily uses macros and a pattern matching to make it
work:
- macros create a subclass `class Route%id < Route # Route__temp_25`
- macros create overloaded methods with the subclass
  `def handle_route(id : Route__temp_25)`
- macros save the instances of these classes in a registry for access with
  metadata `Registry[path] = Route%id.new "some metadata"`
- overloaded methods are run with the subclass from the matching route
  in the registry `instance.handle_route(Registry[path])`
- a fallback implemention is needed for matching the base class `def handle_route(id : Route)`
  for compability (to actually compile) which will never be called
- all created routes are inspectable in the registry

This behavior used can further explained with the following code:
```crystal
# Define a class
class A
end

# Define a registry
REGISTRY = {} of String => A

# Define the which will have the DSL
class B
  # Define the DSL method
  macro make_print(key, text)
    # Create a sub class with a unique name
    class A%name < A
    end

    # Save an instance of that class in the registry
    REGISTRY[{{key}}] = A%name.new

    # Create an overloaded method that responds to that class only
    def handle_print(id : A%name)
      # Run things here
      puts {{text}}
    end
  end

  # Create a fallback method for compability
  def handle_print(id : A)
    puts "fallback"
  end

  # Have a method call the overloaded functions
  def print(key)
    handle_print REGISTRY[key]
  end

  # Actually make the overloaded methods
  make_print "a", "hello"
  make_print "b", "bye"
end

b = B.new
b.print "a" # "hello"
b.print "b" # "bye"
```
