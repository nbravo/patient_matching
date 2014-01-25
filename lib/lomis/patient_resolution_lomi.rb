require 'securerandom'
require 'yaml'
require 'mongo'
include Mongo

module Chla
  class PatientResolutionLomi
    attr_accessor :patients, :encounters, :events

    def initialize(options = {:env => "development"})
      read_config(options)
      @mongo_client = MongoClient.new(@host, @port)
      @db = @mongo_client.db(@database)
      @patients = @db["patients"]
      @encounters = @db["encounters"]
      @events = @db["events"]
    end

    def run
      resolve_patient_ids
      propagate_resolved_patient_ids
      resolve_encounter_ids
    end

    def finish
    end

    def read_config(options)
      env = options[:env]
      @host = CONFIG["host"]
      @port = CONFIG["port"]
      @database = CONFIG[env]["database"]
    end

    # Find all pairs of patients in the picudb and cerner dbs that meet some
    # matching criteria, and assign to those pairs a resolved_patient_id.
    # The matching criteria can be configured through the
    # patient_resolution_selector method
    def resolve_patient_ids
      @patients.find({:source => "picudb"}).each do |patient|
        @patients.update(patient_resolution_selector(patient),
            {:$set => {:resolved_patient_id => SecureRandom.hex}},
            {:multi => true})
      end
    end

    # Once matching patients have been assigned resolved_patient_ids, assign
    # that same resolved_patient_id to their children encounters and events
    def propagate_resolved_patient_ids
      @patients.find().each do |patient|
        patient_id = patient["_id"]
        @encounters.update({:patient_id => patient_id},
            {:$set => {:resolved_patient_id => patient["resolved_patient_id"]}},
            {:multi => true})
        @events.update({:patient_id => patient_id},
            {:$set => {:resolved_patient_id => patient["resolved_patient_id"]}},
            {:multi => true})
      end
    end

    # Take all of the events belonging to patients in the cerner database. For
    # each of those events, find the matching patient in picudb and look at the
    # encounters for that patient. If the event's time interval is contained
    # within the encounter's time interval, then assign to the event a
    # resolved_encounter_id which matches the encounter's object id.
    def resolve_encounter_ids
      @encounters.find({:resolved_patient_id => {:$exists => true}, :source => "picudb"}).each do |picudb_encounter|
        cerner_patient = @patients.find_one({:resolved_patient_id => picudb_encounter["resolved_patient_id"],
            :source => "cerner_patients"})
        @events.update(event_encounter_resolution_selector(cerner_patient, picudb_encounter),
            {:$set => {:resolved_encounter_id => picudb_encounter["_id"]}},
            {:multi => true})
      end
    end

    # Return a hash that can be used as a selector when looking for matching
    # patients.
    def patient_resolution_selector(patient)
      {mrn: patient["mrn"]}
    end

    # Return a hash that can be used as a selector to find events which occur
    # within the time interval specified by a given encounter.
    def event_encounter_resolution_selector(patient, encounter)
      {:patient_id => patient["_id"],
       :end_time => {:$gte => encounter["admission"], :$lt => encounter["discharge"]},
       :start_time => {:$gte => encounter["admission"], :$lt => encounter["discharge"]}}
    end
  end
end

