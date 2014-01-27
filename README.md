# ISRC

Gem to pull isrc code data from [PPL UK's database](http://repsearch.ppluk.com/ARSWeb/appmanager/ARS/main).

Although this gem uses ppluk's DB, the goal is support more DBs as the need arises.

## Installation

Add this line to your application's Gemfile or install manually.

## Usage

	class Song
	  def update_isrc
	    retriever = ISRC::PPLUK.new
	    retriever.retrieve artist: self.artist, title: self.title
	    isrc_match = retriever.match(time: self.song_length)
	
	    self.isrc = isrc_match[:isrc]
	    self.match_quality = isrc_match[:delta]
	  end
	end

## How Does it Work?

We are querying the PPL UK ISRC databases using their [public search tool](http://repsearch.ppluk.com/ARSWeb/appmanager/ARS/main).

The web app is written in Java. It makes an ajax request to grab search results.

The AJAX request will fail unless the request has specific session vars and cookie values based on the response data from the main app response.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Copyright (c) 2012 Michael Bianco, released under the New BSD License