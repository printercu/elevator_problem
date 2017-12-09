module SpecHelpers
  class SubscriberStub
    include Celluloid
    exclusive

    attr_reader :notifier, :state_changes

    def initialize(notifier)
      @notifier = notifier
      reset
    end

    def reset
      @state_changes = []
    end

    def subscribe_for_elevator_state(event = 'elevator:state_changed')
      notifier.subscribe(Actor.current, event, :elevator_state_changed)
    end

    def elevator_state_changed(_event, attr, val, _state)
      state_changes.push([attr, val])
    end

    def waiter
      Waiter.new(self)
    end

    # Have to use separate instance to prevent deadlocks, because subscriber
    # works in exclusive mode.
    class Waiter
      include Celluloid

      attr_reader :subscriber

      def initialize(subscriber)
        @subscriber = subscriber
      end

      # Wait for notifications.
      def wait(timeout: 0.1, interval: 0.001)
        initial_size = subscriber.state_changes.size
        yield if block_given?
        timeout(timeout) do
          loop do
            return if subscriber.state_changes.size > initial_size
            sleep(interval)
          end
        end
      end
    end
  end
end
