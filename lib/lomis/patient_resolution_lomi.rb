require 'securerandom'
require 'mongo'
include Mongo

module Chla
  class PatientResolutionLomi

    def initialize(options = {})
      @mongo_client = MongoClient.new("sherylj", 27017)
      puts "initializing #{self.class}"
    end

    def run
      @db = @mongo_client.db("picu_cerner_match")
      patients = @db["patients"]
      assign_patient_ids(patients)
      propagate_resolved_patient_ids(patients)
      match_dates(patients)
      puts "running #{self.class}"
    end

    def finish
      # TODO: Finish and clean up here.  Some examples:
      # move files, delete directories, close connections, log status, send notifications
      puts "finishing #{self.class}"
    end

    def assign_patient_ids(patients)
      patients.find({:source => "picudb"}).each do |patient|
        patients.update({mrn: patient["mrn"]}, {"$set" => {"resolved_patient_id" => SecureRandom.hex}}, {:multi => true})
      end
    end

    def propagate_resolved_patient_ids(patients)
      encounters = @db["encounters"]
      events = @db["events"]
      patients.find().each do |patient|
        patient_id = patient["_id"]
        encounters.update({:patient_id => patient_id}, {"$set" => {"resolved_patient_id" => patient["resolved_patient_id"]}}, {:multi => true})
        events.update({:patient_id => patient_id}, {"$set" => {"resolved_patient_id" => patient["resolved_patient_id"]}}, {:multi => true})
      end
    end

    def match_dates(patients)
      events = @db["events"]
      encounters = @db["encounters"]
      patients.find({:source => "cerner_patients", :resolved_patient_id => {"$exists" => true}}).each do |cerner_patient|
        picudb_patient_id = patients.find_one({:resolved_patient_id => cerner_patient["resolved_patient_id"], :source => "picudb"})["_id"]
        cerner_events = events.find({:patient_id => cerner_patient["_id"]})
        cerner_events.each do |cerner_event|
          encounters.find({:patient_id => picudb_patient_id}).each do |encounter|
            if within_time_interval(cerner_event, encounter)
              events.update({:_id => cerner_event["_id"]}, {"$set" => {:resolved_encounter_id => encounter["_id"]}})
              break
            end
          end
        end
      end
    end

    # This method checks whether a given event occurs during a given encounter.
    # It requires that the encounter contain both an admission and a discharge
    # date. If the event does not have an end_time (and by assumption, does not
    # have a start_time either), then this method returns false. Otherwise,
    # returns true if the event's start_time and end_time both fall in between
    # the encounter's admission and discharge dates.
    def within_time_interval(event, encounter)
      within = false
      encounter_start = encounter["admission"]
      encounter_end = encounter["discharge"]
      unless event["end_time"].nil? or encounter_start.nil? or encounter_end.nil?
        if event["start_time"].nil?
          within = event["end_time"] >= encounter_start and event["end_time"] <= encounter_end
        else
          within = event["end_time"] >= encounter_start and event["end_time"] <= encounter_end and event["start_time"] >= encounter_start and event["start_time"] <= encounter_end

        end
      end
      return within
    end

  end
end

