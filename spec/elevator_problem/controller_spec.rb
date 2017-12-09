RSpec.describe ElevatorProblem::Controller do
  let(:instance) { described_class.new(elevator, floors_range: 0..10) }
  let(:elevator) do
    ElevatorProblem::Elevator.new(
      floor: initial_floor,
      time_to_floor: time_to_floor,
      open_doors_timeout: open_doors_timeout,
      logger: logger,
    )
  end
  let(:initial_floor) { 5 }
  let(:time_to_floor) { 0.02 }
  let(:open_doors_timeout) { 0.04 }
  let(:logger) { Logger.new('/dev/null') }
  let(:subscriber) { SpecHelpers::SubscriberStub.new(elevator.notifier) }

  describe 'operation' do
    scenario 'open doors when current floor is requested' do
      subscriber.subscribe_for_elevator_state
      expect_waiting_subscriber { instance.external_request(initial_floor) }.
        to change(subscriber, :state_changes).by([[:doors_open, true]])
      expect_waiting_subscriber(expected_interval: open_doors_timeout).
        to change(subscriber, :state_changes).by([[:doors_open, false]])
      subscriber.reset
      expect_waiting_subscriber { instance.internal_request(initial_floor) }.
        to change(subscriber, :state_changes).by([[:doors_open, true]])
      expect_waiting_subscriber(expected_interval: open_doors_timeout).
        to change(subscriber, :state_changes).by([[:doors_open, false]])
    end

    scenario 'keeps doors open when requested again' do
      subscriber.subscribe_for_elevator_state
      expect_waiting_subscriber { instance.external_request(initial_floor) }.
        to change(subscriber, :state_changes).by([[:doors_open, true]])
      expect { sleep(open_doors_timeout * 0.6) }.to_not change(subscriber, :state_changes)
      instance.external_request(initial_floor)
      expect { sleep(open_doors_timeout * 0.6) }.to_not change(subscriber, :state_changes)
      instance.internal_request(initial_floor)
      expect { sleep(open_doors_timeout * 0.6) }.to_not change(subscriber, :state_changes)
      expect { sleep(open_doors_timeout * 0.6) }.
        to change(subscriber, :state_changes).by([[:doors_open, false]])
    end

    scenario 'going to floor with stop on other' do
      subscriber.subscribe_for_elevator_state
      floor_1 = initial_floor + 5
      floor_2 = initial_floor + 3
      floor_3 = initial_floor - 2
      instance.external_request(floor_1)
      sleep(time_to_floor)
      instance.external_request(floor_2)
      sleep(time_to_floor * 2 + open_doors_timeout)
      instance.external_request(floor_3)
      sleep(time_to_floor * 9 + open_doors_timeout * 3 + 0.5)

      expect(subscriber.state_changes).
        to eq(state_changes_for_floors(initial_floor, floor_2, floor_1, floor_3))
    end

    scenario 'going to floor and back to other' do
      subscriber.subscribe_for_elevator_state
      floor_1 = initial_floor + 5
      floor_2 = initial_floor + 3
      instance.external_request(floor_1)
      sleep(time_to_floor * 4)
      instance.external_request(floor_2)
      sleep(time_to_floor * 9 + open_doors_timeout * 2)

      expect(subscriber.state_changes).
        to eq(state_changes_for_floors(initial_floor, floor_1, floor_2))
    end
  end
end
