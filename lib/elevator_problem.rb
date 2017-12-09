require 'logger'
require 'bigdecimal'
require 'bigdecimal/util'
require 'celluloid/current'
require 'elevator_problem/elevator'
require 'elevator_problem/controller'
require 'elevator_problem/readline_input'

module ElevatorProblem
  module_function

  def run_cli
    print 'Floors count: '
    floors = gets.to_i
    print 'Floor height (m): '
    floor_height = gets.to_d
    print 'Velocity (m/s): '
    velocity = gets.to_d
    print 'Open doors timeout (s): '
    open_doors_timeout = gets.to_d
    puts 'Starting...'

    run(
      floors: floors,
      floor_height: floor_height,
      velocity: velocity,
      open_doors_timeout: open_doors_timeout,
    )
  end

  def run(floors: 5, floor_height: 2.0, velocity: 2.0, open_doors_timeout: 2)
    time_to_floor = floor_height / velocity
    elevator = Elevator.new(
      time_to_floor: time_to_floor,
      open_doors_timeout: open_doors_timeout,
      logger: readline_friendly_logger,
    )

    controller = Controller.new(elevator, floors_range: 0...floors)
    ReadlineInput.new(controller).run
  end

  def readline_friendly_logger
    stdout = STDOUT.dup.tap { |x| x.extend(ReadlineInput::FriendlyOutput) }
    logger = Logger.new(stdout)
    logger.formatter = proc do |_severity, datetime, _progname, msg|
      "#{datetime.strftime('%H:%M:%S.%1N')}: #{msg}\n"
    end
    logger
  end
end
