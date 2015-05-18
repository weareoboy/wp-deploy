require "thor"

class WpdCLI < Thor
    include Thor::Actions

    def self.source_root
        File.expand_path("../templates",__FILE__)
    end

    desc "init", "Initialises the WordPress project"
    def init

        if Dir.exist?('config')
            say "wp-deploy: Looks like you've already initialised this project! If you're trying to update your configuration using the settings in your .yml files, try running `bundle exec wpdeploy config` first.", :red
            exit
        end

        say "
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
Welcome to wp-deploy!

To get started, we're going to ask a few questions to configure your
environments. If you would rather do this later, you can manually populate
`config/database.yml` and `config/settings.yml` and run `bundle exec wpdeploy
config` to apply the settings.
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––\n\n", :green

        databaseYaml = ""
        environments = ['local', 'staging', 'production']

        environments.each do |env|
            if yes?("Do you wish to configure your #{env} database now?", :blue)
                dbhostname = ask("What hostname should we use? (usually localhost)", :blue)
                dbname = ask("What is the name of your database?", :blue)
                dbuser = ask("What username should we connect to the database with?", :blue)
                dbpass = ask("What is the password for this user? ", :blue, :echo => false)
                say "\n\n"

                databaseYaml +=
"#{env}:
  host: #{dbhostname}
  database: #{dbname}
  username: #{dbuser}
  password: '#{dbpass}'\n"
            else
                say "#{env} configuration skipped\n\n", :yellow
                databaseYaml +=
"#{env}:
  host: localhost
  database: example
  username: example
  password: 'example'\n"

            end
        end

        create_file "config/database.yml", databaseYaml

    end

    desc "install", "Installs WordPress and configures wp-deploy."
    def install

        # Check if init has been run first
        unless Dir.exist?('config')
            say "wp-deploy: Configuration files not found. Please run `bundle exec init` and set up your configuration files first.", :red
            exit
        end

        # Create base WordPress/wp-deploy files
        say "wp-deploy: Setting up a new wp-deploy project", :green
        directory "."

        # Initialise new git repo
        say "wp-deploy: Checking if we need a new git repo", :green
        system('git init') unless Dir.exist?('.git')

        # Fetch WP core submodule
        say "wp-deploy: Cloning latest WordPress core as a submodule", :green
        system('
            git submodule add https://github.com/WordPress/WordPress.git wordpress
            cd wordpress
            git fetch --tags
            latestTag=$(git tag -l | sort -n -r -t. -k1,1 -k2,2 -k3,3 -k4,4 | sed -n 1p)
            git checkout -q $latestTag
            cd ../
            git add -A
            git commit -m "Set up wp-deploy"
        ')

        say "
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
wp-deploy:

Good to go! Now populate your `database.yml` and `settings.yml` and
run `bundle exec wpdeploy setup`
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––", :green

    end

end