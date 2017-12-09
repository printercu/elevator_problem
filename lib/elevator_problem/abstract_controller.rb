module ElevatorProblem
  # Handles inputs, elevator events and instructs elevator.
  # This abstract class does not provide any logic on how to select
  # next elevator stop, this should be defined in child classes.
  class AbstractController
    include Celluloid

    # Prohibit parallel commands.
    exclusive

    attr_reader :floors_range

    def initialize(elevator, floors_range:)
      @elevator = elevator
      @floors_range = floors_range
      @elevator_state = elevator.state
      @external_requests = []
      @internal_requests = []
      @requests = []
      elevator.notifier.subscribe Actor.current, 'elevator:state_changed', :_elevator_state_changed
    end

    # Add target floor to external requests.
    def external_request(floor)
      add_target_floor(external_requests, floor)
    end

    # Add target floor to internal requests.
    def internal_request(floor)
      add_target_floor(external_requests, floor)
    end

    # Celluloid expects subscriber method to be public, so it can not be protected/private.
    # This method should not be used directly.
    def _elevator_state_changed(_topic, attr, new_value, state)
      @elevator_state = state
      case attr
      when :doors_open
        new_value ? doors_opened : doors_closed
      when :floor
        floor_changed
      end
    end

    def valid_floor?(floor)
      floors_range.include?(floor)
    end

    protected

    attr_reader :elevator, :elevator_state

    # Arrays of floors that was requested with external calls and with
    # pushed buttons inside elevator.
    attr_reader :external_requests, :internal_requests

    def add_target_floor(collection, floor)
      return if collection.include?(floor) || !valid_floor?(floor)
      collection.push(floor)
      process_requests
    end

    # When doors are opened we assume that request was complete and remove current
    # floor from requests.
    def doors_opened
      floor = elevator_state[:floor]
      external_requests.delete(floor)
      internal_requests.delete(floor)
    end

    # Just start processing next request.
    def doors_closed
      process_requests
    end

    # Open door when elevator stoped and current floor was requested.
    def floor_changed
      process_requests if elevator_state[:direction].zero?
    end

    # Fetches action from strategy and passes it to elevator.
    def process_requests
      return if open_doors_if_required
      action, args = next_action
      elevator.public_send(action, *args) if action
    end

    # Opens door if elevator is stopped and current floor was requested.
    # It keeps doors open even if they are open.
    def open_doors_if_required
      return unless elevator_state[:direction].zero?
      floor = elevator_state[:floor]
      return unless external_requests.include?(floor) || internal_requests.include?(floor)
      elevator.open_doors
      # Clear requests if doors are already open because event will not be fired.
      doors_opened if elevator_state[:doors_open]
      true
    end

    def next_action
      raise 'abstract'
    end
  end
end
