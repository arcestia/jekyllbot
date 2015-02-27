require 'sinatra'
require 'json'
require 'git'
require 'jekyll'

get '/' do
  dir = './tmp/jekyll'
  FileUtils.mkdir_p dir

  g = Git.clone('https://micurley:m0j0j0j0@github.com/micurley/micurley.github.io.git', dir)

  FileUtils.rm_rf dir

  'Listening'
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
  FileUtils.mkdir_p dir

  push = JSON.parse(request.body.read)
  if push["commits"].first["author"]["name"] == name
    puts "This is just the callback from JekyllBot's last commit... aborting."
    return
  end

  url = push["repository"]["url"] + ".git"
  url["https://"] = "https://" + username + ":" + password + "@"

  puts "cloning " + url + " into " + dir
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

    stream do |out|
        out << "starting to build in " + dir + "\n"
        begin
            site.process
        rescue Jekyll::Errors::FatalException => e
            puts e.message
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
        out << "Done building\n"
    end
  puts "cleaning up."
  FileUtils.rm_rf dir

  puts "done"

end