require 'bundler/setup'
require './lib/racker'
use Rack::Session::Pool
use Rack::Reloader
use Rack::Static, :urls => ['/css', '/js'], :root => 'public'
run Racker
