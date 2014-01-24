require 'test/unit'
require 'chla'

module Chla
  class ExperimentLomiTest < Test::Unit::TestCase

    def setup
      # TODO: create Lomi
      @lomi = ExperimentLomi.new
    end

    def teardown
      # TODO: any clean up operations
    end

    def test_run
      # TODO: test running the lomi
      @lomi.run
    end

    def test_finish
      # TODO: test finishing the lomi
      @lomi.finish
    end

    # TODO: Add more tests

  end
end
