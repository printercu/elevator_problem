require 'elevator_problem/abstract_controller'

module ElevatorProblem
  # Basic implementation of controller with simple strategy:
  #
  #   - move in one direction while there are any requests in this direction;
  #   - change direction;
  #   - repeat from the begining.
  #
  # TODO: For complex strategies it may be better to extract moving strategy logic
  # to separate class.
  class Controller < AbstractController
    def initialize(*)
      super
      @direction = elevator_state[:direction]
      @requests = []
    end

    protected

    def add_target_floor(_collection, floor)
      requests.push(floor).sort! unless requests.include?(floor)
      super
    end

    def doors_opened
      super
      requests.delete(elevator_state[:floor])
    end

    # List of all requests.
    attr_accessor :requests

    # Elevator direction, not changed when it stops.
    attr_accessor :direction

    def next_action
      return if requests.empty?
      self.direction = init_direction if !direction || direction.zero?
      target_floor = next_floor_in_current_direction
      unless target_floor
        self.direction *= -1
        target_floor = next_floor_in_current_direction
      end
      [:move_to, target_floor] if target_floor
    end

    def init_direction
      target = internal_requests[0] || external_requests[0]
      (target - elevator_state[:floor]).positive? ? 1 : -1
    end

    # Picks next requested floor from current when moving up,
    # and previous to current/next from current when moving down.
    def next_floor_in_current_direction
      current = elevator_state[:floor]
      if direction == 1
        # We can use bsearch because requests array is sorted.
        requests.bsearch { |x| x > current }
      elsif direction == -1
        # bsearch can search only for minimum position, so we search
        # for minimum greater than/equal to current level and take previous for it.
        min_index = requests.bsearch_index { |x| x >= current }
        min_index&.positive? ? requests[min_index - 1] : requests.last
      end
    end
  end
end
