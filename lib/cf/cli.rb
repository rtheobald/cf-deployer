# Encoding: utf-8
require 'thor'

require 'cf/cli/base'
require 'cf/cli/cf'

module CF
  module CLI
    class CLI < Base
      desc 'cf SUBCOMMAND ...ARGS', 'CF tasks'
      subcommand 'cf', Cf
    end
  end
end
