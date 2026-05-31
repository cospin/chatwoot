require 'httparty'

class Google::GmailClient
  BASE_URL = 'https://gmail.googleapis.com/gmail/v1/users/me'.freeze

  class Error < StandardError; end

  pattr_initialize [:channel!]

  def thread_id_for_message_id(message_id)
    message_id_queries(message_id).each do |query|
      thread_id = thread_id_for_query(query)
      return thread_id if thread_id.present?
    end

    nil
  end

  def delete_thread(thread_id)
    return true if thread_id.blank?

    response = request(:delete, "/threads/#{thread_id}")
    return true if not_found?(response)

    ensure_success!(response)
    true
  end

  private

  def thread_id_for_query(query)
    response = request(
      :get,
      '/messages',
      query: {
        q: query,
        includeSpamTrash: true,
        maxResults: 1
      }
    )
    return if not_found?(response)

    ensure_success!(response)
    response.parsed_response&.dig('messages', 0, 'threadId')
  end

  def request(method, path, options = {})
    HTTParty.public_send(method, "#{BASE_URL}#{path}", options.merge(headers: headers))
  rescue HTTParty::Error, SocketError, Net::OpenTimeout, Net::ReadTimeout, OpenSSL::SSL::SSLError, Errno::ECONNREFUSED => e
    raise Error, e.message
  end

  def headers
    {
      'Authorization' => "Bearer #{access_token}",
      'Accept' => 'application/json'
    }
  end

  def access_token
    @access_token ||= Google::RefreshOauthTokenService.new(channel: channel).access_token
  rescue OAuth2::Error, RuntimeError => e
    raise Error, e.message
  end

  def ensure_success!(response)
    return if response.success?

    raise Error, "Gmail API request failed with status #{response.code}: #{response.body}"
  end

  def not_found?(response)
    response.code.to_i == 404
  end

  def message_id_queries(message_id)
    value = message_id.to_s.strip
    return [] if value.blank?

    bare_message_id = value.delete_prefix('<').delete_suffix('>')
    return [] if bare_message_id.blank?

    ["rfc822msgid:#{bare_message_id}", "rfc822msgid:<#{bare_message_id}>"].uniq
  end
end
