require 'test/unit'
require 'chla'

module Chla
  class PatientResolutionLomiTest < Test::Unit::TestCase

    def setup
      @lomi = PatientResolutionLomi.new({:env => "test"})
      clear_test_data
      populate_test_data
    end

    def teardown
      clear_resolved_fields
    end

    def populate_test_data
      @alice_mrn = 123
      @alice_picudb_id = @lomi.patients.insert({:mrn => @alice_mrn, :source => "picudb", :first_name => "Alice"})
      @alice_cerner_id = @lomi.patients.insert({:mrn => @alice_mrn, :source => "cerner_patients", :first_name => "Alice"})

      #bob_picudb_id = @lomi.patients.insert({:mrn => 456, :source => "picudb", :first_name => "Bob"})
      #bob_cerner_id = @lomi.patients.insert({:mrn => 456, :source => "cerner_patients", :first_name => "Bob"})

      @alice_picudb_encounter_id = @lomi.encounters.insert({:patient_id => @alice_picudb_id, :source => "picudb"})
      @alice_cerner_encounter_id = @lomi.encounters.insert({:patient_id => @alice_cerner_id, :source => "cerner_paients"})

      @alice_picudb_event_id = @lomi.events.insert({:patient_id => @alice_picudb_id, :encounter_id => @alice_picudb_encounter_id})
      @alice_cerner_event_id = @lomi.events.insert({:patient_id => @alice_cerner_id, :encounter_id => @alice_cerner_encounter_id})
    end

    def clear_test_data
      @lomi.patients.drop()
      @lomi.encounters.drop()
      @lomi.events.drop()
    end

    def clear_resolved_fields
      @lomi.patients.update({}, {:$unset => {:resolved_patient_id => ""}}, {:multi => true})
      @lomi.encounters.update({}, {:$unset => {:resolved_patient_id => ""}}, {:multi => true})
      @lomi.events.update({}, {:$unset => {:resolved_patient_id => ""}}, {:multi => true})
      @lomi.events.update({}, {:$unset => {:resolved_encounter_id => ""}}, {:multi => true})
    end

    def test_resolve_patient_ids
      assert_equal @lomi.patients.find({:resolved_patient_id => {:$exists => true}}).count(), 0
      @lomi.resolve_patient_ids
      assert_equal @lomi.patients.find_one({:_id => @alice_picudb_id})["resolved_patient_id"], @lomi.patients.find_one({:_id => @alice_cerner_id})["resolved_patient_id"]
    end

    def test_propagate_resolved_patient_ids
      resolved_patient_id = SecureRandom.hex
      @lomi.patients.update({mrn: @alice_mrn}, {"$set" => {"resolved_patient_id" => resolved_patient_id}}, {:multi => true})
      assert_equal @lomi.encounters.find({:resolved_patient_id => {:$exists => true}}).count(), 0
      assert_equal @lomi.events.find({:resolved_patient_id => {:$exists => true}}).count(), 0
      @lomi.propagate_resolved_patient_ids
      assert_equal @lomi.encounters.find_one({:_id => @alice_picudb_encounter_id})["resolved_patient_id"], resolved_patient_id
      assert_equal @lomi.encounters.find_one({:_id => @alice_cerner_encounter_id})["resolved_patient_id"], resolved_patient_id
      assert_equal @lomi.events.find_one({:_id => @alice_picudb_event_id})["resolved_patient_id"], resolved_patient_id
      assert_equal @lomi.events.find_one({:_id => @alice_cerner_event_id})["resolved_patient_id"], resolved_patient_id
    end

    def test_resolve_encounter_ids
    end
  end
end
