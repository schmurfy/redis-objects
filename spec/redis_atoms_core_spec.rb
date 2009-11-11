
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class Roster
  include Redis::Atoms
  counter :available_slots, :start => 10
  counter :num_pitchers, :start => 1

  def id; 1; end
end

describe Redis::Atoms do
  before :all do
    @roster  = Roster.new
    @roster2 = Roster.new

    @roster.clear_available_slots
    @roster.clear_num_pitchers
  end

  after :each do
    @roster.reset_available_slots
    @roster.reset_num_pitchers
  end

  it "should provide a connection method" do
    Roster.connection.should == Redis::Atoms.connection
    Roster.connection.should be_kind_of(Redis)
  end

  it "should create counter accessors" do
    [:available_slots, :increment_available_slots, :decrement_available_slots,
     :reset_available_slots, :clear_available_slots].each do |m|
       @roster.respond_to?(m).should == true
     end
  end
  
  it "should support increment/decrement of counters" do
    @roster.available_slots_counter_name.should == 'roster:1:available_slots'
    @roster.available_slots.should == 10
    @roster.increment_available_slots.should == 11
    @roster.increment_available_slots.should == 12
    @roster2.increment_available_slots.should == 13
    @roster2.increment_available_slots(2).should == 15
    @roster.decrement_available_slots.should == 14
    @roster2.decrement_available_slots.should == 13
    @roster.decrement_available_slots.should == 12
    @roster2.decrement_available_slots(4).should == 8
    @roster.available_slots.should == 8
    @roster.reset_available_slots.should == true
    @roster.available_slots.should == 10
    @roster.reset_available_slots(15).should == true
    @roster.available_slots.should == 15
    @roster.num_pitchers.should == 1
  end
  
  it "should support class-level increment/decrement of counters" do
    Roster.get_counter(:available_slots, @roster.id).should == 10
    Roster.increment_counter(:available_slots, @roster.id).should == 11
    Roster.increment_counter(:available_slots, @roster.id, 3).should == 14
    Roster.decrement_counter(:available_slots, @roster.id, 2).should == 12
    Roster.decrement_counter(:available_slots, @roster.id).should == 11
    Roster.reset_counter(:available_slots, @roster.id).should == true
    Roster.get_counter(:available_slots, @roster.id).should == 10
  end

  it "should properly throw errors on bad counters" do
    error = nil
    begin
      Roster.increment_counter(:badness, 2)
    rescue => error
    end
    error.should_not be_nil
    error.should be_kind_of(Redis::Atoms::UndefinedCounter)
  end
end