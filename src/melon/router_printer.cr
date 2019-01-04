module Melon
  class RoutePrinter
    @lines : Array({String, String})

    def initialize
      @lines = [] of {String, String}
    end

    def p(line)
      @lines.push line
    end

    def print_routes(api, indent = 0, last = false, calculate_last = false)
      fchar = last ? "" : "│"
      indentation = indent == 0 ? "" : fchar.ljust indent
      length = api.routes.size

      return p({">>> There are no routes! <<<", ""}) if length == 0

      api.routes.each_with_index do |route, index|
        is_last = index == length - 1
        first_char = is_last ? "└─" : "├─"
        last = calculate_last ? is_last : last
        if route.resource
          p({indentation + first_char + " RESOURCE #{route.method} - /#{route.path}", route.description})
        elsif route.api?
          p({indentation + first_char + "┬─ API - /#{route.path}", route.api.not_nil!.description})
          print_routes route.api.not_nil!, indent + 2, last
        else
          p({indentation + first_char + " #{route.method} - /#{route.path}", route.description})
        end
      end
    end

    def print(api)
      first_line = api.name
      first_line += " - #{api.description}" unless api.description.empty?
      print_routes api, 0, false, true

      lines = format
      max_line_size = lines.map(&.size).max
      max_size = [max_line_size, first_line.size].max

      puts first_line
      puts "".ljust(max_size, '-')
      puts lines.join("\n")
      puts "".ljust(max_size, '-')
    end

    def format
      max = @lines.map(&.first).map(&.size).max
      @lines.map do |line|
        comment = line[1].empty? ? "" : "# " + line[1]
        line[0].ljust(max + 2) + comment
      end
    end
  end
end
