require 'bundler/setup'
require './lib/racker'
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'KmMXeRjmKM38k8a9'
use Rack::Reloader
use Rack::Static, :urls => [ '/css' ], :root => 'public'
run Racker
