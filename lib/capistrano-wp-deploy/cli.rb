require "thor"

class WpdCLI < Thor
  desc "init", "Initialises the WordPress project"
  def init
    say "Hello world"
  end
end