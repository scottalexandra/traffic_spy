module TrafficSpy
  class Url
    def self.table
      DB.from(:urls)
    end

    def self.find(incoming_url)
      table.where(:url => incoming_url).first
    end

    def self.exists?(incoming_url)
      !table.where(:url => incoming_url).empty?
    end

    def self.find_or_create(incoming_url)
      if exists?(incoming_url)
        url_id = table.select(:id).where(:url => incoming_url).first[:id]
      else
        table.insert(:url => incoming_url)
        url_id = table.where(:url => incoming_url).first[:id]
      end
      url_id
    end

    def self.rank_url(identifier)
      rooturl_length = identifier[:rooturl].length
      Payload.table
        .select(:url, :count)
        .where(:identifier_id => identifier[:id])
        .join(:urls, :id => :url_id)
        .group_and_count(:url)
        .order(Sequel.desc(:count))
        .map do |row|
          row[:relative_path] = row[:url].slice(rooturl_length..-1)
          row
        end
    end

    def self.rank_url_by_reponse_time(identifier)
      rooturl_length = identifier[:rooturl].length
      DB.fetch("select url, avg(responded_in) from payloads pl join urls u on \
        pl.url_id = u.id where pl.identifier_id = #{identifier[:id]} \
        group by u.url order by avg desc").to_a
        .map do |row|
          row[:relative_path] = row[:url].slice(rooturl_length..-1)
          row
        end
    end

    def self.longest_response_time(identifier, url)
      Payload.table
        .where(:identifier_id => identifier[:id], :url => url)
        .join(:urls, :id => :url_id)
        .max(:responded_in)
    end

    def self.shortest_response_time(identifier, url)
      Payload.table
        .where(:identifier_id => identifier[:id], :url => url)
        .join(:urls, :id => :url_id)
        .min(:responded_in)
    end

    def self.average_response_time(identifier, url)
      Payload.table
        .where(:identifier_id => identifier[:id], :url => url)
        .join(:urls, :id => :url_id)
        .avg(:responded_in)
    end

    def self.http_verbs(identifier, url)
      Payload.table
        .select_group(:request_type)
        .where(:identifier_id => identifier[:id], :url => url)
        .join(:urls, :id => :url_id)
        .join(:request_types, :id => :payloads__request_type_id)
        .map { |row| row[:request_type] }
    end

    def self.popular_referrers(identifier, url)
      Payload.table
        .select(:referred_by, :count)
        .where(:identifier_id => identifier[:id], :url => url)
        .join(:urls, :id => :url_id)
        .join(:referred_bys, :id => :payloads__referred_by_id)
        .group_and_count(:referred_by)
        .order(Sequel.desc(:count)).to_a
    end

    def self.popular_user_agents(identifier, url)
      Payload.table
        .select(:browser, :os, :count )
        .where(:identifier_id => identifier[:id], :url => url)
        .join(:urls, :id => :url_id)
        .join(:user_agents, :id => :payloads__user_agent_id)
        .group_and_count(:browser, :os)
        .order(Sequel.desc(:count)).to_a
    end
  end
end
