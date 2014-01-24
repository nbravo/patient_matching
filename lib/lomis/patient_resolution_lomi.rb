require 'securerandom'
require 'yaml'
require 'mongo'
include Mongo

module Chla
  class PatientResolutionLomi
    attr_reader :patients, :encounters, :events
    attr_writer :patients, :encounters, :events

    def initialize(options = {:env => "development"})
      puts "initializing #{self.class}"
      read_config(options)
      @mongo_client = MongoClient.new(@host, @port)
      @db = @mongo_client.db(@database)
      @patients = @db["patients"]
      @encounters = @db["encounters"]
      @events = @db["events"]
    end

    def run
      puts "running #{self.class}"
      resolve_patient_ids
      propagate_resolved_patient_ids
      resolve_encounter_ids
    end

    def finish
      puts "finishing #{self.class}"
    end

    def read_config(options)
      config = YAML::load_file(File.join(File.dirname(File.expand_path(__FILE__)), '../../config/config.yml'))
      env = options[:env]
      @host = config[env]["host"]
      @port = config[env]["port"]
      @database = config[env]["database"]
    end

    def resolve_patient_ids
      @patients.find({:source => "picudb"}).each do |patient|
        @patients.update({mrn: patient["mrn"]}, {"$set" => {"resolved_patient_id" => SecureRandom.hex}}, {:multi => true})
      end
    end

    def propagate_resolved_patient_ids
      @patients.find().each do |patient|
        patient_id = patient["_id"]
        @encounters.update({:patient_id => patient_id}, {"$set" => {"resolved_patient_id" => patient["resolved_patient_id"]}}, {:multi => true})
        @events.update({:patient_id => patient_id}, {"$set" => {"resolved_patient_id" => patient["resolved_patient_id"]}}, {:multi => true})
      end
    end

    def resolve_encounter_ids
      @encounters.find({:resolved_patient_id => {:$exists => true}, :source => "picudb"}).each do |picudb_encounter|
        cerner_patient = @patients.find_one({:resolved_patient_id => picudb_encounter[:resolved_patient_id], :source => "cerner_patients"})
        @events.update({:patient_id => cerner_patient["_id"], :end_time => {"$gte" => picudb_encounter["admission"], "$lt" => picudb_encounter["discharge"]}, :start_time => {"$gte" => picudb_encounter["admission"], "$lt" => picudb_encounter["discharge"]}}, {:$set => {:resolved_encounter_id => picudb_encounter["_id"]}}, {:multi => true})
      end
    end
  end
end

