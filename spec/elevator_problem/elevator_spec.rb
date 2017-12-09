RSpec.describe ElevatorProblem::Elevator, :celluloid do
  let(:instance) do
    described_class.new(
      floor: initial_floor,
      time_to_floor: time_to_floor,
      open_doors_timeout: open_doors_timeout,
      logger: logger,
    )
  end
  let(:initial_floor) { 5 }
  let(:time_to_floor) { 0.04 }
  let(:open_doors_timeout) { 0.06 }
  let(:logger) { Logger.new('/dev/null') }
  let(:subscriber) { SpecHelpers::SubscriberStub.new(instance.notifier) }

  describe '#open_doors' do
    subject { -> { instance.open_doors } }
    it 'opens doors and then closes' do
      expect(&subject).to change(instance, :doors_open).from(nil).to(true)
      expect { sleep(open_doors_timeout) }.to change(instance, :doors_open).to(false)
    end

    it 'notifies about state change' do
      subscriber.subscribe_for_elevator_state
      expect { subject.call }.to change(subscriber, :state_changes).
        by([[:doors_open, true]])
      expect_waiting_subscriber(expected_interval: open_doors_timeout).
        to change(subscriber, :state_changes).by([[:doors_open, false]])
    end
  end

  describe '#direction' do
    subject { -> { instance.direction } }
    it 'returns -1/0/1' do
      set_target_floor = ->(x) { instance.send(:target_floor=, x) }
      expect { set_target_floor[instance.floor + 10] }.to change(&subject).from(0).to(1)
      expect { set_target_floor[instance.floor - 1] }.to change(&subject).to(-1)
      expect { set_target_floor[instance.floor] }.to change(&subject).to(0)
    end
  end

  describe '#move_to' do
    subject { ->(x = target_floor) { instance.move_to(x) } }
    let(:target_floor) { 8 }

    shared_examples 'moves to target floor' do
      it 'moves to floor step by step' do
        should change(instance, :target_floor).to(target_floor)
        floors_sequence(initial_floor, target_floor).each do |floor|
          expect { sleep(time_to_floor) }.to change(instance, :floor).to(floor)
        end
        expect { sleep(time_to_floor) }.to_not change(instance, :floor)
      end

      it 'notifies about state change' do
        subscriber.subscribe_for_elevator_state
        subject.call
        floors_sequence(initial_floor, target_floor).each do |floor|
          expect_waiting_subscriber(expected_interval: time_to_floor).
            to change(subscriber, :state_changes).by([[:floor, floor]])
        end
        expect { sleep(time_to_floor) }.to_not change(subscriber, :state_changes)
      end
    end

    shared_examples 'ignores command' do
      it { should_not change(instance, :target_floor) }
      its(:call) { should eq nil }
    end

    include_examples 'moves to target floor'

    context 'when elevator is moving' do
      before { subject.call(initial_target_floor) }

      shared_examples 'different directions' do |closer:, further:, other_direction:|
        context 'nearer' do
          let(:target_floor, &closer)
          include_examples 'moves to target floor'
        end

        context 'further' do
          let(:target_floor, &further)
          include_examples 'moves to target floor'
        end

        context 'and target is in other direction' do
          let(:target_floor, &other_direction)
          include_examples 'ignores command'
        end
      end

      context 'up' do
        let(:initial_target_floor) { initial_floor + 3 }
        include_examples 'different directions',
          closer: -> { initial_floor + 2 },
          further: -> { initial_floor + 4 },
          other_direction: -> { initial_floor - 1 }
      end

      context 'down' do
        let(:initial_target_floor) { initial_floor - 3 }
        include_examples 'different directions',
          closer: -> { initial_floor - 2 },
          further: -> { initial_floor - 4 },
          other_direction: -> { initial_floor + 1 }
      end
    end

    context 'when doors are open' do
      before { instance.open_doors }
      include_examples 'ignores command'
    end
  end
end
