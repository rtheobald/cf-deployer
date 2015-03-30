require 'thor'

module CF
  module CLI
    class Base < Thor
      class_option :non_interactive, aliases: :n, type: :boolean, desc: 'Non-interactive'
    end
  end
end
