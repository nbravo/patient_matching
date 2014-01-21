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
      patients.find(:source => "picudb").each do |patient|
        patients.update({mrn: patient["mrn"]}, {"$set" => {"resolved_patient_id" => (0...8).map{(65 + rand(26)).chr}.join}}, {:multi => true})
      end
      puts patients.find.to_a
      puts "running #{self.class}"
    end

    def finish
      # TODO: Finish and clean up here.  Some examples:
      # move files, delete directories, close connections, log status, send notifications
      puts "finishing #{self.class}"
    end

  end
end

