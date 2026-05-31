class Conversations::GmailThreadDeletionService
  class Error < StandardError; end

  pattr_initialize [:conversation!]

  def perform
    return true unless google_email_conversation?

    source_ids = message_source_ids
    if source_ids.blank?
      Rails.logger.warn "[Conversations::GmailThreadDeletionService] No message source ids for conversation #{conversation.id}"
      return true
    end

    thread_id = find_thread_id(source_ids)
    if thread_id.blank?
      Rails.logger.warn "[Conversations::GmailThreadDeletionService] Gmail thread not found for conversation #{conversation.id}"
      return true
    end

    gmail_client.delete_thread(thread_id)
    true
  rescue Google::GmailClient::Error => e
    Rails.logger.error "[Conversations::GmailThreadDeletionService] Gmail thread deletion failed for conversation #{conversation.id}: #{e.message}"
    raise Error, I18n.t('errors.gmail.thread_delete_failed')
  end

  private

  def google_email_conversation?
    channel.is_a?(Channel::Email) && channel.google?
  end

  def channel
    @channel ||= conversation.inbox.channel
  end

  def find_thread_id(source_ids)
    source_ids.each do |source_id|
      thread_id = gmail_client.thread_id_for_message_id(source_id)
      return thread_id if thread_id.present?
    end

    nil
  end

  def message_source_ids
    conversation.messages
                .where.not(message_type: Message.message_types[:activity])
                .where(private: false)
                .where.not(source_id: [nil, ''])
                .pluck(:source_id)
                .uniq
  end

  def gmail_client
    @gmail_client ||= Google::GmailClient.new(channel: channel)
  end
end
