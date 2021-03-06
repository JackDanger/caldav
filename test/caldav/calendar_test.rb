require File.dirname(__FILE__) + '/../test_helper.rb'

require 'http'

class CalendarTest < Test::Unit::TestCase
  
  def setup
    @uri = "http://example.com/calendars/users/admin/newcal/"
    @username = "admin"
    @password = "password"
    @calendar = CalDAV::Calendar.new(@uri, :username => @username, :password => @password)
    Net::HTTP.responses = []
    Net::HTTP.requests = []
  end
  
  def test_create
    prepare_response('calendar', 'success')
    cal = CalDAV::Calendar.create(@uri, :username => @username, :password => @password,
      :displayname => "New Calendar", :description => "Calendar Description")
    assert_request 'calendar', 'create'
    assert_kind_of CalDAV::Calendar, cal
  end
  
  def test_unauthorized_failure_on_create
    prepare_response('calendar', '401_Unauthorized')
    begin
      cal = CalDAV::Calendar.create(@uri,
        :displayname => "New Calendar", :description => "Calendar Description")
    rescue CalDAV::Error => error
      assert_request 'calendar', 'create_without_credentials'
      assert_kind_of Net::HTTPResponse, error.response
      assert_equal '401', error.response.code
    rescue
      fail "Should raise CalDAV::Error"
    end
  end
  
  def test_add_event
    prepare_response('calendar', 'success')
    @cal = Icalendar::Calendar.new
    @cal.event do
      dtstart DateTime.parse("20060102T090000Z")
      summary "Playing with CalDAV"
      dtend DateTime.parse("20060102T090000Z")
      dtstamp '20070109T174740'
      uid 'UID'
    end
    assert @calendar.add_event(@cal)
    assert_request 'calendar', 'add_event'
  end
  
  def test_find_all_events
    prepare_response('calendar', 'events')
    events = @calendar.events(DateTime.parse("20060102T000000Z")..DateTime.parse("20060103T000000Z"))
    assert_kind_of Array, events
    assert !events.empty?
    events.each do |event|
      assert_kind_of Icalendar::Event, event
    end
    assert_request 'calendar', 'time_range'
  end
end