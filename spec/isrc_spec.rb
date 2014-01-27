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

    it "handles the case where the primary match is not supplied" do
      
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
    context 'of brackets' do
      it "should parse them correctly with a one word song" do
        pieces = isrc.send(:extract_song_peices, "Surrender [Original Mix]")
        pieces[:all].size.should == 2
        pieces[:all].last.should == "[Original Mix]"
        pieces[:meta].size.should == 1
      end
    end

    context 'of parenthesis' do
      it "should count parenthesis as a single song peice" do
        pieces = isrc.send(:extract_song_peices, "Want Me (Like Water) (New Vocal Mix No 1)")
        pieces[:all].size.should == 4
        pieces[:all].last.should == '(New Vocal Mix No 1)'
        pieces[:meta].size.should == 2
        pieces[:title].size.should == 2
      end

      it "should handle a single word song with parenthesis" do
        isrc.retrieve artist:'Niko', title: 'Womb (Flight Facilities feat. Giselle)'
        isrc.match(time:'3:44')[:isrc].should == 'GBKNX0500003'

        isrc = ISRC::PPLUK.new
        isrc.retrieve artist:'Frank Sinatra', title: 'Chicago (Digitally Remastered)'
        isrc.match(time:'2:14')[:isrc].should == 'USCA20300966'
        # or USCA29800388; they are basically the same
      end
    end

    it "should handle a standard multi-word title" do
      pieces = isrc.send(:extract_song_peices, "Take Your Time")
      pieces[:all].size.should == 3
      pieces[:title].size.should == 3
      pieces[:title].last.should == "Time"
    end

  end
end