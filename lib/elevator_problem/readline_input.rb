require 'readline'

module ElevatorProblem
  # Input that reads commands from console using readline.
  class ReadlineInput
    attr_reader :controller

    def initialize(controller)
      @controller = controller
    end

    def run(help: true)
      if help
        puts 'Use o{num} for external elevator calls, i{num} for button pushes inside elevator.'
      end
      loop do
        str = Readline.readline('', true)
        Readline.delete_text # Prevent old text appear after Readline.refresh_line is called
        process(str) if str
      end
    end

    def process(str)
      floor = str[1..-1].to_i
      unless controller.valid_floor?(floor)
        puts "Invalid floor number. Valid range: #{controller.floors_range.inspect}"
        return
      end
      case str[0]
      when 'o' then controller.external_request(floor)
      when 'i' then controller.internal_request(floor)
      else puts 'Invalid command'
      end
    end

    # Add this to output IO to make it keep current readline input while outputting.
    module FriendlyOutput
      def write(str)
        current_line = Readline.line_buffer.size
        return super if current_line.empty?
        str = str.to_s
        str = "\r#{str}" + ' ' * [current_line.size - str.size, 0].max
        super.tap { Readline.refresh_line }
      end
    end
  end
end
