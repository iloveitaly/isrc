require 'spec_helper'
require 'isrc'

describe ISRC do
  it "should properly configure session data" do
    
  end

  it "should correctly handle a single search result" do
    isrc = ISRC::PPLUK.new
    isrc.retrieve artist: 'Coldplay', title: 'Clocks'
    isrc.match('5:08').should == 'GBAYE0800410'
  end

  context "multiple results" do
    
  end
end