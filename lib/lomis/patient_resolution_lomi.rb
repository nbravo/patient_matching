require 'mongo'
include Mongo

module Chla
  class PatientResolutionLomi

    def initialize(options = {})
      @mongo_client = MongoClient.new("sherylj", 27017)
      puts "initializing #{self.class}"
      puts 'hey ho'
    end

    def run
      @db = @mongo_client.db("picu_cerner_match")
      patients = @db["patients"]
      assign_patient_ids(patients)
      propagate_resolved_patient_ids(patients)
      puts patients.find.to_a
      puts "running #{self.class}"
    end

    def finish
      # TODO: Finish and clean up here.  Some examples:
      # move files, delete directories, close connections, log status, send notifications
      puts "finishing #{self.class}"
    end

    def assign_patient_ids(patients)
      patients.find(:source => "picudb").each do |patient|
        patients.update({mrn: patient["mrn"]}, {"$set" => {"resolved_patient_id" => (0...8).map{(65 + rand(26)).chr}.join}}, {:multi => true})
      end
    end

    def propagate_resolved_patient_ids(patients)
      encounters = @db["encounters"]
      events = @db["events"]
      patients.find().each do |patient|
        patient_id = patient["_id"]
        encounters.update({:patient_id => patient_id}, {"$set" => {"resolved_patient_id" => patient["resolved_patient_id"]}}, {:multi => true})
        encounters.find({:patient_id => patient_id}).each do |encounter|
          encounter_id = encounter["_id"]
          events.update({:encounter_id => encounter_id}, {"$set" => {"resolved_patient_id" => patient["resolved_patient_id"]}}, {:multi => true})
        end
      end
    end

    def time_match(patients)
      events = @db["events"]
      events.find().each do |event|
        if patients.find({:resolved_patient_id => event["resolved_patient_id"]})["source"] == "cerner"
        end
      end
    end

  end
end

