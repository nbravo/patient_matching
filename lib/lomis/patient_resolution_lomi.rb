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
      #assign_patient_ids(patients)
      #propagate_resolved_patient_ids(patients)
      match_dates(patients)
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

    def match_dates(patients)
      puts 'match dates'
      events = @db["events"]
      encounters = @db["encounters"]
      events.find().each do |event|
        resolved_patient_id = event["resolved_patient_id"]
        patients.find({:resolved_patient_id => resolved_patient_id, :source => "picudb"}).each do |patient|
          patient_encounters = encounters.find({:patient_id => patient["_id"]})
          patient_encounters.each do |patient_encounter|
            if within_time_interval(event, encounter)
              events.update({:_id => event["_id"]}, {"$set" => {:resolved_encounter_id => encounter["_id"]}})
              break
            end
          end
        end
      end
      puts 'done with match dates'
    end

  end
end

