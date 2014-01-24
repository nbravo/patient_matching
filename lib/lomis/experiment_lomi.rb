module Chla
  class ExperimentLomi

    def initialize(options = {})
      @mongo_client = MongoClient.new("sherylj", 27017)
      @db = @mongo_client.db("picu_cerner_match")
      @patients = @db["patients"]
      @encounters = @db["encounters"]
      @events = @db["events"]
    end

    def run
      puts "running #{self.class}"
=begin
      encounter = @encounters.find({:eid => 33367}).to_a.first
      puts encounter["admission"]
      puts encounter["discharge"]
      @matching_events = @events.find({:end_time => {"$gte" => encounter["admission"], "$lt" => encounter["discharge"]}, :start_time => {"$gte" => encounter["admission"], "$lt" => encounter["discharge"]}})
      puts @matching_events.to_a
=end
      puts @patients.find({}, {:fields => [:_id]}).to_a.map{|item| item.values}.flatten
    end

    def finish
      puts "finishing #{self.class}"
    end

  end
end

