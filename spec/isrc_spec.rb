require 'spec_helper'
require 'isrc'

describe ISRC do
  before { @isrc = ISRC::PPLUK.new }
  let(:isrc) { @isrc }

  it "should correctly handle multiple search results" do
    isrc.retrieve artist: 'Coldplay', title: 'Clocks'
    isrc.match(time:'5:08')[:isrc].should == 'GBAYE0200771'
  end

  it "should correctly handle a single search result" do
    isrc.retrieve artist: 'Coldplay', title: 'Glass'
    isrc.match(time:'5:08')[:isrc].should == 'GBAYE0800410'
  end

  context "should handle songs with multiple results" do
    it "when the results have the same title and time code" do
      isrc.retrieve artist:'Parade', title:'Louder'
      isrc.match(time:'2:53')[:isrc].should == 'GBAHS1000333'
    end

    it "handles different names" do
      isrc.retrieve artist:'Soul II Soul', title: 'Back To Life (However Do You Want Me) (Club Mix)'
      isrc.match(time:'7:39')[:isrc].should == 'GBAAA8900153'

      # the better match seems to be: GB1209500610
      # however, the length delta is huge
    end

    it "handles edge cases that don't make sense" do
      isrc.retrieve artist:'Toni Braxton', title:'Youre Making me High'
      isrc.match(time:'4:12')[:isrc].should == 'USLF29600183'
    end
  end

  it "should handle songs with no results" do
    isrc.retrieve artist:'The Rurals', title: 'Take Your Time'
    isrc.match(time:'7:27')[:isrc].should == 'No Match'

    isrc = ISRC::PPLUK.new
    isrc.retrieve artist:'Slut Puppies', title:'Funky Together' 
    isrc.match(time:'6:36')[:isrc].should == 'No Match'
  end

  context "song title processing" do
    it "should handle bracket mixes" do
      pieces = isrc.send(:extract_song_peices, "Surrender [Original Mix]")
      pieces.size.should == 2
      pieces.last.should == "[Original Mix]"
    end

    it "should handle parenthesis mixes" do
      pieces = isrc.send(:extract_song_peices, "Want Me (Like Water) (New Vocal Mix No 1)")
      pieces.size.should == 4
      pieces.last.should == '(New Vocal Mix No 1)'
    end

    it "should handle a standard multi-word title" do
      pieces = isrc.send(:extract_song_peices, "Take Your Time")
      pieces.size.should == 3
      pieces.last.should == "Time"
    end
  end
end