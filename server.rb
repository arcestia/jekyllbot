require 'sinatra'
require 'json'
require 'git'
require 'jekyll'
require 'yaml'

get '/' do
  dir = './tmp/jekyll'
  FileUtils.mkdir_p dir

  before = Dir.entries(dir)

  options = {}
  options["server"] = false
  options["auto"] = false
  options["safe"] = false
  options["source"] = dir
  options["destination"] = File.join( dir, '_site')
  options["plugins"] = File.join( dir, '_plugins')
  options = Jekyll.configuration(options)

  g = Git.clone('https://micurley:m0j0j0j0@github.com/micurley/micurley.github.io.git', dir)

  after = Dir.entries(dir)

  FileUtils.rm_rf dir
    opts = YAML.dump options

  'Listening: <br />Before:<br />' + before.join('<br />') + '<br />After\n' + after.join('<br />') +  opts
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
    before = Dir.entries(dir)
    puts 'Dir: ' + before.join('<br />\n')
STDOUT.flush
    stream do |out|
        out << "starting to build in " + dir + "\n"
        begin
            does_it_exist = File.directory?(dir)
            puts 'Dir exists: ' +  '[' + does_it_exist + ']'
            STDOUT.flush
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
        out << "Done building\n"
    end
  puts "cleaning up."
  FileUtils.rm_rf dir

  puts "done"

end