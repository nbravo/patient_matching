require 'test/unit'
require 'chla'

module Chla
  class PatientMatchProcessorTest < Test::Unit::TestCase

    def setup
      # TODO: create processor and mock data
      @processor = PatientMatchProcessor.new
      @obj = Object.new
    end

    def teardown
      # TODO: any clean up operations
    end

    def test_process
      # TODO: test implementation
      result = @processor.process(@obj)
      assert_not_nil result
    end

    # TODO: Add more tests

  end
end
