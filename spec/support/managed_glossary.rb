# Copyright 2025 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

module ManagedGlossary
  # Bounded retry budget for tolerating a freshly-created glossary that is not
  # yet resolvable on the real API (eventual consistency): up to ~10 seconds.
  GLOSSARY_RETRY_ATTEMPTS = 20
  GLOSSARY_RETRY_DELAY = 0.5

  def with_managed_glossary(name:, source_lang:, target_lang:, entries:, options: {})
    glossary = DeepL.glossaries.create(name, source_lang, target_lang, entries, options)
    yield glossary
  ensure
    begin
      DeepL.glossaries.destroy(glossary.id) if glossary
    rescue StandardError
      nil
    end
  end

  # A just-created glossary is not always immediately resolvable by id on the
  # real API (eventual consistency). Poll #find until each glossary is
  # retrievable so subsequent calls (e.g. translate with glossary_ids) do not
  # fail with a transient "Glossary <uuid> not found" error.
  #
  # Note: no keyword arguments here — Ruby 2.7 would fold a trailing options
  # hash from callers into keywords, breaking positional-hash APIs.
  def wait_until_glossaries_ready(*glossaries)
    glossaries.each do |glossary|
      remaining = GLOSSARY_RETRY_ATTEMPTS
      begin
        DeepL.glossaries.find(glossary.id)
      rescue DeepL::Exceptions::RequestError
        raise if (remaining -= 1) <= 0

        sleep(GLOSSARY_RETRY_DELAY)
        retry
      end
    end
  end

  # Translate with a bounded retry that tolerates a transient
  # "Glossary <uuid> not found" error caused by eventual consistency on a
  # freshly created glossary. Depending on timing the real API returns this as
  # either a 400 or a 404, so match on the message rather than the status.
  # Any other error is re-raised immediately.
  #
  # `options` is an explicit positional hash (matching DeepL.translate) rather
  # than keyword arguments, so passing `{ glossary_ids: [...] }` works on Ruby
  # 2.7 as well as 3.x.
  def translate_retrying_missing_glossary(text, source_lang, target_lang, options = {})
    remaining = GLOSSARY_RETRY_ATTEMPTS
    begin
      DeepL.translate(text, source_lang, target_lang, options)
    rescue DeepL::Exceptions::RequestError => e
      raise unless e.to_s.match?(/glossary .* not found/i)
      raise if (remaining -= 1) <= 0

      sleep(GLOSSARY_RETRY_DELAY)
      retry
    end
  end
end
