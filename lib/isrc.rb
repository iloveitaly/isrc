require "isrc/version"

require 'nokogiri'
require 'mechanize'
require 'logger'

module ISRC
  # NOTE the cont=A is crucial to getting the trick to work
  PPLUK_SESSION_GRAB_URL = 'http://repsearch.ppluk.com/ARSWeb/appmanager/ARS/main'
  PPLUK_AJAX_SEARCH_URL = 'http://repsearch.ppluk.com/ARSWeb/block/send-receive-updates'

  class PPLUK
    def retrieve(opts)
      agent = Mechanize.new
      agent.log = Logger.new "mech.log"
      agent.user_agent_alias = 'Mac Safari'

      isrc_session_init = agent.get PPLUK_SESSION_GRAB_URL
      view_state = self.extract_view_state(isrc_session_init.body)
      ice_session, ice_session_count = self.extract_ice_session(isrc_session_init.body)

      # add the ice_sessions cookie
      ice_cookie = Mechanize::Cookie.new('ice.sessions', "#{ice_session}##{ice_session_count}")
      ice_cookie.path = "/"
      ice_cookie.domain = "repsearch.ppluk.com"
      agent.cookie_jar.add!(ice_cookie)

      begin
        isrc_search = agent.post PPLUK_AJAX_SEARCH_URL, {
          'ice.submit.partial' => 'false',
          'ice.event.target' => 'T400335881332330323192:ars_form:search_button',
          'ice.event.captured' => 'T400335881332330323192:ars_form:search_button',
          'ice.event.type' => 'onclick',
          'ice.event.alt' => 'false',
          'ice.event.ctrl' => 'false',
          'ice.event.shift' => 'false',
          'ice.event.meta' => 'false',
          'ice.event.x' => '47',
          'ice.event.y' => '65',
          'ice.event.left' => 'false',
          'ice.event.right' => 'false',
          'T400335881332330323192:ars_form:search_button' => 'Search',
          'T400335881332330323192:ars_form:isrc_code' => '',
          'T400335881332330323192:ars_form:rec_title_idx' => '',
          'T400335881332330323192:ars_form:rec_title' => opts[:title],
          'T400335881332330323192:ars_form:rec_band_artist_idx' => '',
          'T400335881332330323192:ars_form:rec_band_artist' => opts[:artist],
          'javax.faces.RenderKitId' => 'ICEfacesRenderKit',
          'javax.faces.ViewState' => view_state,
          'icefacesCssUpdates' => '',
          'T400335881332330323192:ars_form' => '',
          'ice.session' => ice_session,
          'ice.view' => view_state,
          'ice.focus' => '',

          # the rand is 19 characters long in the browser's HTTP requests
          'rand' => sprintf('%1.17f', rand)
        }
      rescue Mechanize::ResponseCodeError => e
        agent.log.error "The Stuff #{e.page.body}"
      end

      isrc_html = Nokogiri::HTML(isrc_search.body)
      @matches = isrc_html.css("table[id='T400335881332330323192:ars_form:searchResultsTable'] tbody tr").map { |m| m.css('td').map &:text }
    end

    def match(seconds = nil)
      return @matches.first[2] if @matches.count == 1
      
      if seconds
        
      end

      @matches.first[2]
    end

    protected
    def extract_view_state(body)
      body.match(/javax\.faces\.ViewState" value="([0-9])"/)[1]
    end

    def extract_ice_session(body)
      session_info = body.match(/history-frame:([^:]+):([0-9]+)/)
      [session_info[1], session_info[2].to_i]
    end

  end
end
