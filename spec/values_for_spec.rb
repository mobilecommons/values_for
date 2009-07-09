require 'rubygems'
require 'activerecord'

require File.join(File.dirname(__FILE__), 'spec_helper')

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :dbfile => ":memory:"
)

ActiveRecord::Migration.verbose = false

ActiveRecord::Base.silence do
  ActiveRecord::Schema.define do
    create_table :tacos do |table|
      table.string :state
    end
  end
end


describe EnumFor do
  before do
    @taco = Taco.new(:state => 'new')
  end
  
  class Taco < ActiveRecord::Base
    values_for :state, :has => [ :new, :composed, :served, :eaten ]
  end

  describe "model validation" do
    it "should make a valid model when given a valid state" do
      @taco.should be_valid
    end

    it "should retrieve a symbol when the model is created with attribute set to string" do
      @taco.state.should == :new
    end

    it "should be valid when an attribute is set to a valid symbol" do
      Taco.new(:state => :composed).should be_valid
    end

    it "should not be valid when an attribute is set to an invalid symbol" do
      Taco.new(:state => :bogus).should_not be_valid
    end

    it "should not create a valid model when given an invalid state" do
      Taco.create(:state => 'barfed').should_not be_valid
    end
  end
  
  describe "storage and retrieval of possible states in class" do
    it "should return all possible states when plural of attribute is called as class method" do
      Taco.states.should == [ :new, :composed, :served, :eaten ]
    end
  end
  
  describe "definition of constants for each attribute value" do
    class WithoutConstants < ActiveRecord::Base
      values_for :state, :has => [ :new, :composed, :served, :eaten ]
    end
    
    class WithConstants < ActiveRecord::Base
      values_for :state, :has => [ :new, :composed, :served, :eaten ], :add => :constants
    end
    
    it "should be disabled by default" do
      WithoutConstants.constants.should_not include('WithoutConstants::STATE_NEW')
    end
    
    it "should be enabled when added" do
      WithConstants.constants.should_not include('WithoutConstants::STATE_NEW')
    end

    it "should define constants for each type" do
      WithConstants::STATE_EATEN.should == :eaten
    end
  end
  
  describe "definition of predicate methods" do
    class WithPredicateMethods < ActiveRecord::Base
      set_table_name "tacos"
      values_for :state, :has => [ :new, :composed, :served, :eaten ], :add => :predicate_methods
    end
    
    it "should not define predicate methods for each valid state by default" do
      @taco.should_not respond_to(:state_eaten?)
    end
    
    it "should define predicate methods for each state when specified" do
      WithPredicateMethods.new.should respond_to(:state_eaten?)
    end
  end

  describe "with prefix option" do
    class Food < ActiveRecord::Base
      set_table_name "tacos"
      values_for :state, :has => [:stuff, :morestuff], :prefix => nil, :add => :predicate_methods
    end

    it "should not prefix predicate methods if asked not to" do
      Food.new(:state => :stuff).should respond_to(:stuff?)
    end
  end
  
  describe "casting of values set and retrieved to correct type" do
    it "should allow strings for attribute values even when initialized with symbols" do
      Food.new(:state => 'stuff').should be_valid
    end
    
    it "should retrieve a symbol when a string is set and the attribute value is a symbol" do
      f = Food.new(:state => 'stuff')
      f.state.should == :stuff
    end
  end
  
  describe "with an Array of additives" do
    class BeefJerkey < ActiveRecord::Base
      set_table_name "tacos"
      values_for :flavor, :has => [:sour, :spicy], :add => [:named_scopes, :predicate_methods]
    end
    
    it "should construct named scopes" do
      BeefJerkey.should respond_to(:flavor_sour)
    end
    
    it "should construct predicate methods" do
      BeefJerkey.new.should respond_to(:flavor_sour?)
    end
  end
  
  describe "when a user tries to set an empty String as a valid value" do
    it "should raise an IllegalArgumentError" do
      lambda {
        class Food2 < ActiveRecord::Base
          set_table_name "tacos"
          values_for :state, :has => ['stuff', '']
        end
      }.should raise_error(ArgumentError)
    end
  end
  
  describe "behavior with existing methods of same name" do
    class Balloon < ActiveRecord::Base
      set_table_name "tacos"
      values_for :state, :has => [:stuff, :morestuff], :prefix => nil

      def stuff?
        "not a boolean"
      end
    end

    it "should not define a predicate method when a one already exists" do
      Balloon.new(:state => :stuff).stuff?.should == "not a boolean"
    end
  end

  describe "with validation options" do   
    class Food2 < ActiveRecord::Base
      set_table_name "tacos"
      values_for :state, :has => ['stuff', 'morestuff'], :prefix => nil, :allow_nil => true, :message => "is great!"
    end

    it "should allow validation message to be set" do
      Food2.create(:state => :junk).errors.full_messages.should include('State is great!')
    end
    
    it "should respect :allow_nil setting" do
      Food2.new.should be_valid
    end
  end
  
  describe "getting and setting nil values" do
    class Food2 < ActiveRecord::Base
      set_table_name "tacos"
      values_for :state, :has => ['stuff', 'morestuff'], :prefix => nil, :allow_nil => true, :message => "is great!"
    end
    
    before do
      @f = Food2.new
      @f.state = nil
    end
    
    it "should return a nil value without error" do
      lambda {
        @f.state
      }.should_not raise_error
    end
    
    it "should return nil when nil is set" do
      @f.state.should == nil
    end
    
    it "should store nil when nil is set" do
      @f.state_before_type_cast.should == nil
    end
  end
  
  describe "named scope creation" do
    describe "when not added" do
      it "should not create named scopes" do
        Taco.should_not respond_to(:state_composed)
      end
    end
    
    describe "when added" do
      class Tequila < ActiveRecord::Base
        set_table_name "tacos"
        values_for :state, :has => [ :wormy, :delicious ], :add => :named_scopes
      end

      before do
        Tequila.delete_all
      
        2.times { Tequila.create(:state => 'wormy') }
        3.times { Tequila.create(:state => 'delicious') }
      end
    
      it "should have two wormy tequilas" do
        Tequila.state_wormy.size.should == 2
      end
    
      it "should have three delicious tequilas" do
        Tequila.state_delicious.size.should == 3
      end
    end
  end
  
end
