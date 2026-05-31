require 'rails_helper'

RSpec.describe Conversations::GmailThreadDeletionService do
  let(:account) { create(:account) }
  let(:channel) do
    create(
      :channel_email,
      account: account,
      provider: 'google',
      provider_config: {
        access_token: 'access-token',
        refresh_token: 'refresh-token',
        expires_on: 1.hour.from_now.to_s
      }
    )
  end
  let(:conversation) { create(:conversation, account: account, inbox: channel.inbox) }
  let(:gmail_client) { instance_double(Google::GmailClient) }

  subject(:service) { described_class.new(conversation: conversation) }

  before do
    allow(Google::GmailClient).to receive(:new).with(channel: channel).and_return(gmail_client)
  end

  context 'when the conversation does not belong to a Google OAuth email inbox' do
    let(:channel) { create(:channel_email, account: account) }

    it 'does not call Gmail' do
      expect(Google::GmailClient).not_to receive(:new)

      expect(service.perform).to be true
    end
  end

  context 'when Gmail resolves a thread from a message source id' do
    before do
      create(:message, conversation: conversation, account: account, inbox: channel.inbox, source_id: 'missing@example.com')
      create(:message, conversation: conversation, account: account, inbox: channel.inbox, source_id: 'found@example.com')
      create(:message, conversation: conversation, account: account, inbox: channel.inbox, source_id: 'activity@example.com', message_type: :activity)
      create(:message, conversation: conversation, account: account, inbox: channel.inbox, source_id: 'private@example.com', private: true)

      allow(gmail_client).to receive(:thread_id_for_message_id).with('missing@example.com').and_return(nil)
      allow(gmail_client).to receive(:thread_id_for_message_id).with('found@example.com').and_return('gmail-thread-id')
      allow(gmail_client).to receive(:delete_thread).with('gmail-thread-id').and_return(true)
    end

    it 'deletes the first matching Gmail thread and skips private/activity messages' do
      expect(gmail_client).not_to receive(:thread_id_for_message_id).with('activity@example.com')
      expect(gmail_client).not_to receive(:thread_id_for_message_id).with('private@example.com')

      expect(service.perform).to be true
      expect(gmail_client).to have_received(:delete_thread).with('gmail-thread-id')
    end
  end

  context 'when Gmail cannot resolve any message to a thread' do
    before do
      create(:message, conversation: conversation, account: account, inbox: channel.inbox, source_id: 'missing@example.com')
      allow(gmail_client).to receive(:thread_id_for_message_id).with('missing@example.com').and_return(nil)
    end

    it 'continues without deleting a remote thread' do
      expect(gmail_client).not_to receive(:delete_thread)

      expect(service.perform).to be true
    end
  end

  context 'when Gmail API deletion fails' do
    before do
      create(:message, conversation: conversation, account: account, inbox: channel.inbox, source_id: 'message@example.com')
      allow(gmail_client).to receive(:thread_id_for_message_id).and_return('gmail-thread-id')
      allow(gmail_client).to receive(:delete_thread).and_raise(Google::GmailClient::Error, 'forbidden')
    end

    it 'raises a user-facing service error' do
      expect { service.perform }
        .to raise_error(described_class::Error, I18n.t('errors.gmail.thread_delete_failed'))
    end
  end
end
