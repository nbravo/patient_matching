require 'test/unit'
require 'chla'

module Chla
  class PatientResolutionLomiTest < Test::Unit::TestCase

    def setup
      @lomi = PatientResolutionLomi.new({:env => "test"})
      populate_test_data
    end

    def teardown
      clear_resolved_fields
    end

    def populate_test_data
      alice_picudb_id = @lomi.patients.insert({:mrn => 123, :source => "picudb", :first_name => "Alice"})
      alice_cerner_id = @lomi.patients.insert({:mrn => 123, :source => "cerner_patients", :first_name => "Alice"})

      bob_picudb_id = @lomi.patients.insert({:mrn => 456, :source => "picudb", :first_name => "Bob"})
      bob_cerner_id = @lomi.patients.insert({:mrn => 456, :source => "cerner_patients", :first_name => "Bob"})
    end

    def clear_resolved_fields
      @lomi.patients.update({}, {:$unset => {:resolved_patient_id => ""}}, {:multi => true})
      @lomi.encounters.update({}, {:$unset => {:resolved_patient_id => ""}}, {:multi => true})
      @lomi.events.update({}, {:$unset => {:resolved_patient_id => ""}}, {:multi => true})
      @lomi.events.update({}, {:$unset => {:resolved_encounter_id => ""}}, {:multi => true})
    end

    def test_run
      @lomi.run
    end

    # TODO: Add more tests

  end
end
