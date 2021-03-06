require 'sinatra'
require 'sinatra/contrib'
require 'json'
require 'git'
require 'jekyll'
require 'yaml'

get '/' do
    stream do |out|
        dir = './tmp/jekyll'
        name = "JekyllBot"
        email = "arcestia@vivaldi.net"
        username = ENV['GH_USER'] || 'arcestiabot'
        password = ENV['GH_PASS'] || '1lovececil'

        FileUtils.rm_rf dir

        url = 'https://' + username + ":" + password + '@github.com/arcestia/arcestia.github.io' + '.git'

        out.puts "cloning " + url + " into " + dir
        g = Git.clone(url, dir)

        options = {}
        options["server"] = false
        options["auto"] = false
        options["safe"] = false
        options["source"] = dir
        options["destination"] = File.join( dir, '_site')
        options["plugins"] = File.join( dir, '_plugins')
        options = Jekyll.configuration(options)
        site = Jekyll::Site.new(options)

        begin
            out.puts "Starting site process"
            out.puts site.process
        rescue Jekyll::Errors::FatalException => e
            FileUtils.rm_rf dir
            exit(1)
        end

        out.puts "succesfully built; commiting..."

        begin
            g.config('user.name', name)
            g.config('user.email', email)
            out.puts  g.status
            g.add(:all=>true)
            out.puts  g.commit_all("[JekyllBot] Building JSON files")
        rescue Git::GitExecuteError => e
            out.puts  e.message
        else
            out.puts  "pushing"
            out.puts  g.push
            out.puts  "pushed"
        end

        out.puts  "cleaning up."
        FileUtils.rm_rf dir

        out.puts  "done"
        out.flush
    end
end

post '/' do
    push = JSON.parse(request.body.read)
    pusher = push["commits"].first["author"]["name"]
    repo = push["repository"]["url"] + ".git"

    "Relavent Info: " + pusher + "pushed to " + url
end

post '/webhook' do
  dir = './tmp/jekyll'
  name = "JekyllBot"
  email = "morgan.curley+bot@gmail.com"
  username = ENV['GH_USER'] || ''
  password = ENV['GH_PASS'] || ''

  FileUtils.rm_rf dir

  push = JSON.parse(request.body.read)
  if push["commits"].first["author"]["name"] == name
    puts "This is just the callback from JekyllBot's last commit... aborting."
    return
  end

  url = push["repository"]["url"] + ".git"
  url["https://"] = "https://" + username + ":" + password + "@"

  puts "cloning " + url + " into " + dir
  g = Git.clone(url, dir)

  FileUtils.makedirs File.join( dir, '_site')

  options = {}
  options["server"] = false
  options["auto"] = false
  options["safe"] = false
  options["source"] = dir
  options["destination"] = File.join( dir, '_site')
  options["plugins"] = File.join( dir, '_plugins')
  options = Jekyll.configuration(options)
  site = Jekyll::Site.new(options)
    STDOUT.flush
    begin
        site.process
    rescue Jekyll::Errors::FatalException => e
        FileUtils.rm_rf dir
        exit(1)
    end

    puts "succesfully built; commiting..."
    begin
        g.config('user.name', name)
        g.config('user.email', email)
        puts g.commit_all( "[JekyllBot] Building JSON files")
    rescue Git::GitExecuteError => e
        puts e.message
    else
        puts "pushing"
        puts g.push
        puts "pushed"
    end

  puts "cleaning up."
  FileUtils.rm_rf dir

  puts "done"

end

# Needed in post version
#  push = JSON.parse(request.body.read)
#  if push["commits"].first["author"]["name"] == name
#    puts "This is just the callback from JekyllBot's last commit... aborting."
#    return
#  end

#  url = push["repository"]["url"] + ".git"

#  url = push["repository"]["url"] + ".git"
#  url["https://"] = "https://" + username + ":" + password + "@"


# Manually added
