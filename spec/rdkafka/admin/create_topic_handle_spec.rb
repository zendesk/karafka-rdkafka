# frozen_string_literal: true

describe Rdkafka::Admin::CreateTopicHandle do
  let(:response) { 0 }

  subject do
    Rdkafka::Admin::CreateTopicHandle.new.tap do |handle|
      handle[:pending] = pending_handle
      handle[:response] = response
      handle[:error_string] = FFI::Pointer::NULL
      handle[:result_name] = FFI::MemoryPointer.from_string("my-test-topic")
    end
  end

  describe "#wait" do
    let(:pending_handle) { true }

    it "should wait until the timeout and then raise an error" do
      expect {
        subject.wait(max_wait_timeout: 0.1)
      }.to raise_error Rdkafka::Admin::CreateTopicHandle::WaitTimeoutError, /create topic/
    end

    context "when not pending anymore and no error" do
      let(:pending_handle) { false }

      it "should return a create topic report" do
        report = subject.wait

        expect(report.error_string).to eq(nil)
        expect(report.result_name).to eq("my-test-topic")
      end

      it "should wait without a timeout" do
        report = subject.wait(max_wait_timeout: nil)

        expect(report.error_string).to eq(nil)
        expect(report.result_name).to eq("my-test-topic")
      end
    end
  end

  describe "#raise_error" do
    let(:pending_handle) { false }

    before { subject[:response] = -1 }

    it "should raise the appropriate error when there is an error" do
      expect {
        subject.raise_error
      }.to raise_exception(Rdkafka::RdkafkaError, /Unknown broker error \(unknown\)/)
    end
  end
end
