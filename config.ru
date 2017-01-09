require 'bundler/setup'
require './lib/racker'
use Rack::Session::Pool
use Rack::Reloader
use Rack::Static, :urls => [ '/css' ], :root => 'public'
run Racker
