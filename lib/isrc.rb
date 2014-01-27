require "isrc/version"

require 'nokogiri'
require 'mechanize'
require 'logger'

module ISRC
  # NOTE the cont=A is crucial to getting the trick to work
  PPLUK_SESSION_GRAB_URL = 'http://repsearch.ppluk.com/ARSWeb/appmanager/ARS/main'
  PPLUK_AJAX_SEARCH_URL = 'http://repsearch.ppluk.com/ARSWeb/block/send-receive-updates'

  def self.configure(&block)
    ISRC::Configuration.instance_eval(&block)
  end

  class PPLUK
    def retrieve(opts)
      opts = { :title_size => 2 }.merge(opts)

      # NOTE the online search is a bit funky: adding more to the search make the results worse
      # trying out a three word limit

      title_pieces = self.extract_song_peices(opts[:title])
      shortened_title = title_pieces.slice(0, [opts[:title_size], title_pieces.size].min).join(' ')

      @matches = self.request({title: shortened_title, artist: opts[:artist]})

      # if the shortened title did not work, try making it longer
      if @matches.empty? && opts[:title_size] < title_pieces.size
        self.retrieve(opts.merge({:title_size => opts[:title_size] + 1}))
      end
    end

    def match(opts = {})
      return {
        :isrc => 'No Match',
        :delta => -1
      } if @matches.count == 0

      return {
        :artist => @matches.first[0],
        :title => @matches.first[1],
        :isrc => @matches.first[2],
        :delta => 0
      } if @matches.count == 1

      seconds = opts[:time]

      if seconds
        # if string, convert to integer. Format '5:08'
        seconds = timestring_to_integer(seconds) if seconds.class == String
        match_quality = []

        @matches.each do |song_match|
          song_seconds = timestring_to_integer(song_match[5].match(/([0-9]:[0-9]{2})/)[1])
          match_quality << { :delta => (song_seconds - seconds).abs, :match => song_match }
        end

        best_match = match_quality.min_by { |m| m[:delta] }

        return {
          :artist => best_match[:match][0],
          :title => best_match[:match][1],
          :isrc => best_match[:match][2],
          :delta => best_match[:delta]
        }
      end

      nil
    end

    protected
      def extract_song_peices(title)
        # this splits a song title into peices:
        #   * 'bracket' peice (meta)
        #   * 'parenthesis' peice (meta)
        #   * song words (title)

        all_pieces = title.split(/(\([^)]+\)|\[[^\]]+\])/).reject { |s| s.strip.empty? }
        title_pieces = all_pieces.shift.split(' ')
        meta_pieces = all_pieces

        {
          all: [title_pieces, meta_pieces].flatten,
          meta: meta_pieces,
          title: title_pieces
        }
      end

      def extract_view_state(body)
        body.match(/javax\.faces\.ViewState" value="([0-9])"/)[1]
      end

      def extract_ice_session(body)
        session_info = body.match(/history-frame:([^:]+):([0-9]+)/)
        [session_info[1], session_info[2].to_i]
      end

      def timestring_to_integer(time_string)
        minutes, seconds = time_string.split(':')
        minutes.to_i * 60 + seconds.to_i
      end

      def request(opts = {})
        # puts "Title: #{shortened_title}\nArtist: #{opts[:artist]}"

        agent = Mechanize.new
        # TODO log path needs to be configurable
        agent.log = Logger.new "mech.log"
        agent.user_agent_alias = 'Mac Safari'

        # grab the main page HTML to pull session vars to make the AJAX request
        isrc_session_init = agent.get(PPLUK_SESSION_GRAB_URL)
        view_state = self.extract_view_state(isrc_session_init.body)
        ice_session, ice_session_count = self.extract_ice_session(isrc_session_init.body)

        # add the ice_sessions cookie for the AJAX search request
        ice_cookie = Mechanize::Cookie.new('ice.sessions', "#{ice_session}##{ice_session_count}")
        ice_cookie.path = "/"
        ice_cookie.domain = "repsearch.ppluk.com"
        agent.cookie_jar.add!(ice_cookie)

        begin
          isrc_search = agent.post PPLUK_AJAX_SEARCH_URL, {
            'ice.submit.partial' => 'false',
            # 'ice.event.target' => 'T400335881332330323192:ars_form:search_button',
            # 'ice.event.captured' => 'T400335881332330323192:ars_form:search_button',
            # 'ice.event.type' => 'onclick',
            # 'ice.event.alt' => 'false',
            # 'ice.event.ctrl' => 'false',
            # 'ice.event.shift' => 'false',
            # 'ice.event.meta' => 'false',
            # 'ice.event.x' => '47',
            # 'ice.event.y' => '65',
            # 'ice.event.left' => 'false',
            # 'ice.event.right' => 'false',
            'T5000782701386267377497:ars_form:search_button' => 'Search',
            'T5000782701386267377497:ars_form:isrc_code' => '',
            'T5000782701386267377497:ars_form:rec_title_idx' => '',
            'T5000782701386267377497:ars_form:rec_title' => opts[:title],
            'T5000782701386267377497:ars_form:rec_band_artist_idx' => '',
            'T5000782701386267377497:ars_form:rec_band_artist' => opts[:artist],
            'javax.faces.RenderKitId' => 'ICEfacesRenderKit',
            'javax.faces.ViewState' => view_state,
            'icefacesCssUpdates' => '',
            'T5000782701386267377497:ars_form' => '',
            'ice.session' => ice_session,
            'ice.view' => view_state,
            'ice.focus' => '',

            # the rand is 19 characters long in the browser's HTTP requests
            'rand' => sprintf('%1.17f', rand)
          }
        rescue Mechanize::ResponseCodeError => e
          agent.log.error "Error submitting AJAX request: #{e.page.body}"
        end

        # creates an array representation of the table:
        #   artist, title, isrc, rights holder, released, time

        isrc_table = Nokogiri::HTML(isrc_search.body).css("table[id='T5000782701386267377497:ars_form:searchResultsTable'] tbody tr")
        isrc_table.map do |m|
          columns = m.css('td')

          # if there is no ISRC don't bother looking
          next if columns[2] == 'Not Supplied'

          # zero length music wont be used
          next if columns[-1] == '0:00sec'

          columns.map &:text
        end
      end

  end
end
