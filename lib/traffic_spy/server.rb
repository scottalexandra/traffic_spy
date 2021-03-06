require 'json'
module TrafficSpy
  class Server < Sinatra::Base
    set :views, 'lib/views'

    get '/' do
      erb :index
    end

    post '/sources' do
      status_message = Identifier.register(params)
      status status_message[:status]
      body status_message[:body]
    end

    post '/sources/:identifier/data' do
      status_message = Payload.create(params)
      status status_message[:status]
      body status_message[:body]
    end

    get '/sources/:identifier.?:format?' do
      protected!
      clean_param! :identifier
      if Identifier.exists?(params[:identifier])
        @event_identifier  = params[:identifier]
        @identifier        = Identifier.find(params[:identifier])
        @rank_url          = Url.rank_url(@identifier)
        @rank_browser      = Agent.rank_browser(@identifier)
        @rank_os           = Agent.rank_os(@identifier)
        @resolution        = Resolution.display_resolution(@identifier)
        @avg_response_time = Url.rank_url_by_reponse_time(@identifier)
        if params[:format] == :json
          identifier_display_json
        else
          erb :identifier_display
        end
      else
        @message = "The identifier #{params[:identifier]} has not been registered"
        erb :error
      end
    end

    get '/sources/:identifier/urls/:relative_path.?:format?' do
      protected!
      clean_param! :relative_path
      identifier = Identifier.find(params[:identifier])
      @url = identifier[:rooturl] +"/"+ params[:relative_path]
      if Url.exists?(@url)
        @longest_response_time  = Url.longest_response_time(identifier, @url)
        @shortest_response_time = Url.shortest_response_time(identifier, @url)
        @average_response_time  = Url.average_response_time(identifier, @url)
        @http_verbs             = Url.http_verbs(identifier, @url)
        @popular_referrers      = Url.popular_referrers(identifier, @url)
        @popular_user_agents    = Url.popular_user_agents(identifier, @url)
        if params[:format] == :json
          urls_display_json
        else
          erb :url_display
        end
      else
        @message = "The url #{@url} has never been requested"
        erb :error
      end
    end

    get '/sources/:identifier/events' do
      protected!
      @identifier = params[:identifier]
      @events_list = EventName.display_events(Identifier.find(params[:identifier]))
      erb :events
    end

    get '/sources/:identifier/events/:event_name.?:format?' do
      protected!
      clean_param! :event_name
      @identifier = params[:identifier]
      @event_name = params[:event_name]
      @event_details = EventName.event_details(Identifier.find(@identifier), @event_name)
      @events_by_hour = EventName.hour_by_hour(@event_details)
      @total_count = EventName.total_count(@event_details)
      if params[:format] == :json
        event_name_display_json
      else
        erb :event_details
      end
    end

    def protected!
      return if authorized?
      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end

    def authorized?
      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      @auth.provided? && @auth.basic? &&
      @auth.credentials && @auth.credentials == ['admin', 'admin']
    end

    not_found do
      erb :error
    end

    private

    def identifier_display_json
      content_type :json
      {
        identifier: @identifier,
        rank_url: @rank_url,
        rank_browser: @rank_browser,
        rank_os: @rank_os,
        resolution: @resolution,
        avg_response_time: @avg_response_time
      }.to_json
    end

    def urls_display_json
      content_type :json
      {
        longest_response_time: @longest_response_time,
        shortest_response_time: @shortest_response_time,
        average_response_time: @average_response_time,
        http_verbs: @http_verbs,
        popular_referrers: @popular_referrers,
        popular_user_agents: @popular_user_agents
      }.to_json
    end

    def event_name_display_json
      content_type :json
      {
        identifier: @identifier,
        event_name: @event_name,
        event_details: @event_details,
        events_by_hour: @events_by_hour,
        total_count: @total_count,
      }.to_json
    end

    def clean_param!(param_name)
      if params[param_name].end_with? '.json'
        params[param_name] = params[param_name].slice(0..-6)
        params[:format] = :json
      end
    end
  end
end
