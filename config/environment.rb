lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

ENV['RACK_ENV'] ||= 'development'

Dir[File.expand_path('../initializers/*.rb', __FILE__)].each { |f| require f }
