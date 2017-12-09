module SpecHelpers
  # Generate array with floors sequence when moving between floors.
  # Drops first element by default, because it is very handy.
  def floors_sequence(from, to, drop: 1)
    result = (from..to).to_a
    result = (to..from).to_a.reverse if result.size.zero?
    drop ? result.drop(drop) : result
  end

  # Generate list of changes that should be publiched by elevator when it travels
  # along provided list of floors.
  def state_changes_for_floors(*floors, open: true)
    result = []
    floors.reduce do |from, to|
      result += floors_sequence(from, to).map { |x| [:floor, x] }
      result += [[:doors_open, true], [:doors_open, false]] if open
      to
    end
    result
  end

  # Same as `expect {}` but automatically waits until subscriber receives any updates.
  # Checks for spent time if `expected_interval` is provided.
  def expect_waiting_subscriber(subscriber = self.subscriber, expected_interval: nil,
                                **options, &block)
    options[:timeout] = expected_interval * 2 if expected_interval
    expect do
      start = Time.now.to_f
      subscriber.waiter.wait(**options, &block)
      finish = Time.now.to_f
      if expected_interval
        expect(finish - start).to be_within(0.2 * expected_interval).of(expected_interval)
      end
    end
  end

  RSpec.configuration.include self
end
