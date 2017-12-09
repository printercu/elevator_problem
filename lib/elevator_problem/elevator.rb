module ElevatorProblem
  # Low-level elevator emulator. It can just perform badic actions
  # and notifies when it's state is changed.
  #
  # It supposed to be as simple as possible and to not bother whether
  # about strategy at all. So it even does not open doors automatically as
  # it may be not necessary in some cases.
  class Elevator
    include Celluloid

    # Operations order in elevator is significant.
    exclusive

    STATE_ATTRS = %i[floor doors_open].freeze

    # Options
    attr_reader :time_to_floor, :open_doors_timeout

    # Infrastructure
    attr_reader :notifier, :logger

    # State
    attr_reader :target_floor, *STATE_ATTRS

    def initialize(floor: 0, time_to_floor:, open_doors_timeout:, logger:)
      @floor = floor
      @target_floor = floor
      @time_to_floor = time_to_floor
      @open_doors_timeout = open_doors_timeout
      @notifier = Celluloid::Notifications::Fanout.new_link
      @logger = logger
    end

    # Make doors opened, and close it after open_doors_timeout.
    # Resets timeout when called while doors are opened.
    # Returns false if doors can not be opened, otherwise - true.
    def open_doors
      return false unless direction.zero?
      if @open_doors_timer
        @open_doors_timer.reset
        logger.info { 'Keeping doors opened' }
      else
        @open_doors_timer = after(open_doors_timeout) do
          @open_doors_timer = nil
          self.doors_open = false
          logger.info { 'Close doors' }
        end
        self.doors_open = true
        logger.info { 'Open doors' }
      end
      true
    end

    # Sets new target floor. Returns falsy value if new value has not been applied:
    # elevator is moving in other direction or doors open.
    def move_to(new_target_floor)
      return if doors_open
      case direction
      when 1
        return unless new_target_floor > floor
      when -1
        return unless new_target_floor < floor
      end
      self.target_floor = new_target_floor
      run
      true
    end

    # Stops on the next floor in current direction.
    # def stop
    #   self.target_floor += floor + direction
    # end

    # Returns integer: 0 - stopped, -1 - down, 1 - up.
    def direction
      target_floor <=> floor
    end

    def state
      {
        floor: floor,
        target_floor: target_floor,
        doors_open: doors_open,
        direction: direction,
      }
    end

    protected

    attr_writer :target_floor, *STATE_ATTRS

    # Runs elevator if posible and if required.
    def run
      return if @running || doors_open || direction.zero?
      @running = true
      run! { @running = nil }
      true
    end

    # This method just wraps timer to restart it easily.
    # Call #run insted.
    def run!(&block)
      after(time_to_floor) do
        self.floor += direction
        logger.info { "Floor: #{floor}" }
        if direction.zero?
          block&.call
        else
          run!(&block)
        end
      end
    end

    # Call state_changed when any of state attrs is changed.
    module NotifyOnStateChange
      protected

      STATE_ATTRS.each do |attr|
        define_method("#{attr}=") do |val|
          return if val == send(attr)
          super(val).tap { state_changed(attr, val) }
        end
      end

      def state_changed(attr, new_val)
        notifier.publish('elevator:state_changed', attr, new_val, state)
      end
    end

    prepend NotifyOnStateChange
  end
end
