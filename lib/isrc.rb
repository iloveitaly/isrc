require "isrc/version"

require 'httparty'
require 'cgi'

require 'mechanize'

module ISRC
  PPLUK_SESSION_GRAB_URL = 'http://repsearch.ppluk.com/ARSWeb/appmanager/ARS/main?cont=A'
  PPLUK_AJAX_SEARCH_URL = 'http://repsearch.ppluk.com/ARSWeb/block/send-receive-updates'

  class PPLUK
    # def self.retrieve opts
    #   agent = Mechanize.new
    #   page = agent.get(PPLUK_SESSION_GRAB_URL)
    #   google_form = page.form('T400335881332330323192:ars_form')
    #   google_form.post PPLUK_AJAX_SEARCH_URL
    # end
      def self.retrieve(opts = {})
        session_request = HTTParty.get PPLUK_SESSION_GRAB_URL, :headers => { 'Connection' => 'keep-alive' }, :debug_output => $stderr
        session_cookies = CGI::Cookie::parse(session_request.headers["set-cookie"])
        # session_id = cookies['JSESSIONID'].value

        # get the 'ice' session
        session_info = session_request.response.body.match(/history-frame:([^:]+):([0-9]+)/)
        ice_session = session_info[1]
        ice_session_count = session_info[2].to_i
        view_state = session_request.response.body.match(/javax\.faces\.ViewState" value="([0-9])"/)[1]

        cookies = { 'JSESSIONID' => session_cookies['JSESSIONID'].value.first }
        cookies['ice.sessions'] = "#{ice_session}##{ice_session_count}"
        cookies = cookies.map { |key, value| "#{key}=#{value}" }.join("; ")
        puts cookies
        HTTParty.post 'http://repsearch.ppluk.com/ARSWeb/block/dispose-views',
          :body => {
            ice_session => 1,
            'rand' => rand
          },
          :debug_output => $stderr

        isrc_search = HTTParty.post PPLUK_AJAX_SEARCH_URL, 
          :body => {
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
            'T400335881332330323192%3Aars_form%3Asearch_button' => 'Search',
            'T400335881332330323192%3Aars_form%3Aisrc_code' => '',
            'T400335881332330323192%3Aars_form%3Arec_title_idx' => '',
            'T400335881332330323192%3Aars_form%3Arec_title' => opts[:title],
            'T400335881332330323192%3Aars_form%3Arec_band_artist_idx' => '',
            'T400335881332330323192%3Aars_form%3Arec_band_artist' => opts[:artist],
            'javax.faces.RenderKitId' => '',
            'javax.faces.ViewState' => view_state,
            'icefacesCssUpdates' => '',
            'T400335881332330323192%3Aars_form' => '',
            'ice.session' => ice_session,
            'ice.view' => view_state,
            'ice.focus' => '',
            'rand' => sprintf('%1.17f', rand)
          },
          :headers => {
            'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit/537.1 (KHTML, like Gecko) Chrome/21.0.1152.0 Safari/537.1',
            'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
            'Accept' => '*/*',
            'Host' => 'repsearch.ppluk.com',
            'Origin' => 'http://repsearch.ppluk.com',
            'Referer' => PPLUK_SESSION_GRAB_URL,
            'Cookie' => cookies,
            'Accept-Encoding' => 'gzip,deflate,sdch',
            'Accept-Language' => 'en-US,en;q=0.8',
            'Accept-Charset' => 'ISO-8859-1,utf-8;q=0.7,*;q=0.3',
            'Connection' => 'keep-alive',
            'X-RequestedWith' => 'XmlHttpRequest'
          },
          :debug_output => $stderr

        puts isrc_search.headers.inspect
        isrc_search.response.body
      end
  end
end
