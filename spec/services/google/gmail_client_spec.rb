require 'rails_helper'

RSpec.describe Google::GmailClient do
  let(:access_token) { 'gmail-access-token' }
  let(:channel) do
    create(
      :channel_email,
      provider: 'google',
      provider_config: {
        access_token: access_token,
        refresh_token: 'refresh-token',
        expires_on: 1.hour.from_now.to_s
      }
    )
  end
  let(:token_service) { instance_double(Google::RefreshOauthTokenService, access_token: access_token) }

  subject(:client) { described_class.new(channel: channel) }

  before do
    allow(Google::RefreshOauthTokenService).to receive(:new).with(channel: channel).and_return(token_service)
  end

  describe '#thread_id_for_message_id' do
    let(:messages_url) { 'https://gmail.googleapis.com/gmail/v1/users/me/messages' }

    it 'searches Gmail by normalized RFC822 message id' do
      request = stub_request(:get, messages_url)
                .with(
                  query: hash_including(
                    'q' => 'rfc822msgid:<message@example.com>',
                    'includeSpamTrash' => 'true',
                    'maxResults' => '1'
                  ),
                  headers: { 'Authorization' => "Bearer #{access_token}" }
                )
                .to_return(
                  status: 200,
                  body: { messages: [{ id: 'gmail-message-id', threadId: 'gmail-thread-id' }] }.to_json,
                  headers: { 'Content-Type' => 'application/json' }
                )

      expect(client.thread_id_for_message_id('message@example.com')).to eq('gmail-thread-id')
      expect(request).to have_been_requested
    end

    it 'keeps an already bracketed RFC822 message id bracketed once' do
      request = stub_request(:get, messages_url)
                .with(query: hash_including('q' => 'rfc822msgid:<message@example.com>'))
                .to_return(
                  status: 200,
                  body: { messages: [{ id: 'gmail-message-id', threadId: 'gmail-thread-id' }] }.to_json,
                  headers: { 'Content-Type' => 'application/json' }
                )

      expect(client.thread_id_for_message_id('<message@example.com>')).to eq('gmail-thread-id')
      expect(request).to have_been_requested
    end

    it 'returns nil when Gmail has no matching message' do
      stub_request(:get, messages_url)
        .to_return(status: 200, body: { messages: [] }.to_json, headers: { 'Content-Type' => 'application/json' })

      expect(client.thread_id_for_message_id('missing@example.com')).to be_nil
    end

    it 'treats a 404 as already unavailable' do
      stub_request(:get, messages_url).to_return(status: 404, body: '{}')

      expect(client.thread_id_for_message_id('missing@example.com')).to be_nil
    end

    it 'raises an error on Gmail API failures' do
      [401, 403, 429, 500].each do |status|
        message_id = "message-#{status}@example.com"
        stub_request(:get, messages_url)
          .with(query: hash_including('q' => "rfc822msgid:<#{message_id}>"))
          .to_return(status: status, body: '{}')

        expect { client.thread_id_for_message_id(message_id) }
          .to raise_error(described_class::Error, /#{status}/)
      end
    end
  end

  describe '#delete_thread' do
    let(:thread_url) { 'https://gmail.googleapis.com/gmail/v1/users/me/threads/gmail-thread-id' }

    it 'deletes the Gmail thread permanently' do
      request = stub_request(:delete, thread_url)
                .with(headers: { 'Authorization' => "Bearer #{access_token}" })
                .to_return(status: 204, body: '')

      expect(client.delete_thread('gmail-thread-id')).to be true
      expect(request).to have_been_requested
    end

    it 'treats a 404 as already deleted' do
      stub_request(:delete, thread_url).to_return(status: 404, body: '{}')

      expect(client.delete_thread('gmail-thread-id')).to be true
    end

    it 'raises an error on Gmail API failures' do
      [401, 403, 429, 500].each do |status|
        thread_id = "gmail-thread-id-#{status}"
        thread_url = "https://gmail.googleapis.com/gmail/v1/users/me/threads/#{thread_id}"
        stub_request(:delete, thread_url).to_return(status: status, body: '{}')

        expect { client.delete_thread(thread_id) }
          .to raise_error(described_class::Error, /#{status}/)
      end
    end
  end
end
