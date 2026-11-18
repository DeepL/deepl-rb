# Upgrading to 4.0.0

Version 4.0.0 removes everything that 3.10.0 deprecated, most of all the module-level API
(`DeepL.configure`, `DeepL.translate`, `DeepL.glossaries`, ...). If your code calls methods on
the `DeepL` module, it must move to `DeepL::Client`. Code that already uses `DeepL::Client`
needs smaller changes: stricter option and argument checks, different retry behaviour for calls
that create resources, and a few changed error classes and return values. Ruby 3.0 or later is
now required. The full list of changes is in the [CHANGELOG](CHANGELOG.md).

To find deprecated calls before you upgrade, run your tests on 3.10.0 and fix every deprecation
warning.

## Requirements

- Ruby 3.0 or later. The gem declares `required_ruby_version >= 3.0`; on Ruby 2.x, stay on
  deepl-rb 3.x.
- No runtime gem dependency was added or removed.
- An `https://` proxy needs net-http 0.5.0 or later (bundled with Ruby 3.4). On Ruby 3.0 to 3.3,
  add `gem 'net-http', '>= 0.5'` to your Gemfile. See [Client and options](#client-and-options).

## Quick checklist

1. Replace `DeepL.configure` and the module-level calls with a `DeepL::Client`:
   [Client and options](#client-and-options).
2. Pass the key and server URL yourself; nothing reads `DEEPL_AUTH_KEY` or `DEEPL_SERVER_URL`:
   [Client and options](#client-and-options).
3. Rename `glossary_id:` to `glossary:` for text and document translation:
   [Text translation](#text-translation).
4. Fix misspelled options; unknown options now raise `ArgumentError`:
   [Text translation](#text-translation).
5. Move document, glossary, style rule and translation memory calls to the `Client` methods:
   [Documents](#documents), [Glossaries](#glossaries), [Style rules](#style-rules),
   [Translation memories](#translation-memories).
6. Read usage through `usage.character`: [Usage](#usage).
7. Rescue `DeepL::Exceptions::ConnectionError` for network failures, and `ArgumentError` for
   invalid arguments: [Errors, validation and retries](#errors-validation-and-retries).
8. Check your own retry logic around calls that create resources:
   [Errors, validation and retries](#errors-validation-and-retries).
9. Do not download into an existing file: [Documents](#documents),
   [Translation memories](#translation-memories).
10. Replace `configured_rules.numbers` with `configured_rules.fetch('numbers', {})`:
    [Style rules](#style-rules).

## Client and options

The module-level API is removed: `DeepL.configure`, `DeepL.configuration`, `DeepL.api`,
`DeepL.http_client`, `DeepL.with_session`, and the global configuration behind them.
`DeepL::Configuration` is no longer public. Each `DeepL::Client` owns its configuration and
connection.

```ruby
# Before (3.x)
DeepL.configure do |config|
  config.auth_key = 'your-key'
  config.host = 'https://api.deepl.com'
end

# After
client = DeepL::Client.new('your-key', server_url: 'https://api.deepl.com')
```

`DeepL::Client.new(auth_key, server_url:, headers:, max_retries:, timeout:, proxy:,
send_platform_info:, app_info:, http_client_options:, logger:)` replaces the old settings:

| Removed | Use |
| ------- | --- |
| `DeepL.with_session`, `DeepL.http_client`, `DeepL.api` | `proxy:` and `http_client_options:` |
| per-call `additional_headers` | `headers:` |
| `config.user_agent` | `app_info:`, `send_platform_info:`, or a `User-Agent` in `headers:` |
| `config.version=`, `config.max_doc_status_queries=` | removed without replacement |

Changes in behaviour:

- **No environment variables.** `DEEPL_AUTH_KEY` and `DEEPL_SERVER_URL` are no longer read.
  ```ruby
  client = DeepL::Client.new(ENV.fetch('DEEPL_AUTH_KEY'),
                             server_url: ENV.fetch('DEEPL_SERVER_URL', nil))
  ```
- **Default timeout** is 10 seconds per attempt, was 60. Pass `timeout: 60` to keep the old value.
- **`server_url`** must be an absolute `http` or `https` URL with a host, otherwise
  `ArgumentError` is raised when the client is built. Trailing slashes are removed.
- **Proxy** must be an `http://` or `https://` URL (String or `URI`) or a hash with `proxy_addr`
  and `proxy_port`. Any other scheme (for example `socks5://`) or value raises `ArgumentError`.
  An `https` proxy is now connected to over TLS, which needs net-http 0.5.0 or later and an
  `https` server URL. Before, it was used as a plain HTTP proxy. A proxy URL with an empty host
  (`http://`, `http://:8080`) and a proxy hash with a blank `proxy_addr` raise `ArgumentError`
  too. This applies to `Client.new`, `AdminClient.new` and `DeepL::HTTPClientOptions`.
- **`nil` means the default** for `max_retries:`, `timeout:` and `send_platform_info:` (5, 10
  seconds, `true`), like an omitted keyword. Before, `timeout: nil` used Net::HTTP's 60-second
  timeouts and `send_platform_info: nil` left the OS and Ruby versions out of the `User-Agent`.
  Pass `send_platform_info: false` to leave them out.

## Text translation

`DeepL.translate` and `DeepL.rephrase` are replaced by `Client#translate_text` and
`Client#rephrase_text`.

```ruby
# Before (3.x)
DeepL.translate('Hello', 'EN', 'DE', formality: 'more')
DeepL.rephrase('Hello there', 'EN-US', 'business', 'confident')

# After
client.translate_text('Hello', 'EN', 'DE', formality: 'more')
client.rephrase_text('Hello there', 'EN-US', writing_style: 'business', tone: 'confident')
```

- `translate_text` returns an array when you pass an array, also an array with one element.
- `glossary_id:` is removed; use `glossary:`, which takes a glossary ID or a glossary object.
  The same applies to document translation.
  ```ruby
  client.translate_text('Hello', 'EN', 'DE', glossary: glossary_id)
  ```
- `show_billed_characters` is no longer accepted; the library always requests it.
- **Unknown options raise `ArgumentError`**, naming the option, before any request. Before, they
  were sent as body fields (text, rephrase, correction, glossary, spoken terms, style rule and
  style profile methods) or silently dropped (document translation, translation memory import).
  Fix misspelled options, and send fields the library does not model with
  `extra_body_parameters:`.
  ```ruby
  client.translate_text('Hello', 'EN', 'DE', extra_body_parameters: { new_field: 'value' })
  ```
- `translate_text` and `rephrase_text` raise `ArgumentError` for an empty text (an empty string,
  an empty array, or an array containing an empty string). `rephrase_text` and `correct_text`
  raise it for `target_lang: ''`; `nil` still keeps the language of the text.
- `translate_text`, `translate_document` and `translate_document_upload` raise `ArgumentError`
  for an empty or `nil` `target_lang`, an empty `source_lang` (pass `nil` to detect it), and a
  `translation_memory_threshold` without `translation_memory` or outside 0 to 100.
- The same three methods raise `ArgumentError` when `glossary`, `style_rule`, `style_profile` or
  `translation_memory` is an empty ID or a resource object without its ID, or when
  `glossary_ids` has an empty entry or a glossary without its ID (`translate_document` wraps it
  in `DeepL::Exceptions::DocumentTranslationError`). Before, they were sent empty or as `null`.
  `nil` for one of the four options still leaves it unset.

## Documents

`DeepL.document` and `DeepL::DocumentApi` are removed. Use the `Client` methods.

```ruby
# Before (3.x)
handle = DeepL.document.upload('in.docx', 'EN', 'DE', 'in.docx')
DeepL.document.get_status(handle)
DeepL.document.download(handle, 'out.docx')

# After
handle = client.translate_document_upload('in.docx', 'EN', 'DE', filename: 'in.docx')
status = client.translate_document_wait_until_done(handle)
client.translate_document_download(handle, 'out.docx')
```

- `translate_document(input, output, source_lang, target_lang)` returns the final
  `DeepL::Resources::DocumentTranslationStatus`, was the number of bytes written.
- `translate_document_download` returns `nil`.
- `DocumentHandle#wait_until_document_translation_finished` is removed; use
  `Client#translate_document_wait_until_done`, which raises
  `DeepL::Exceptions::Error` with the API's message if the translation fails or `timeout_s`
  expires.
- `DocumentTranslationStatus#successful?` is removed; use `#done?`.
- `translate_document_download` no longer overwrites a file. Before the request it raises
  `Errno::EEXIST` if `output_path` exists, and `Errno::ENOENT` or `Errno::EACCES` if its
  directory is missing or not writable. Delete the old file first.
- `translate_document` checks the output path before uploading, so a bad path fails at once
  instead of after the translation. It raises `DeepL::Exceptions::DocumentTranslationError`
  (`document_handle` is `nil`) for an existing output file and for a directory that is missing
  or not writable (the `SystemCallError` is its `cause`), and for an invalid upload argument,
  such as an unknown option (the `ArgumentError` is its `cause`). A missing input file still raises `ArgumentError`.
- `translate_document_upload` raises `Errno::EISDIR` before any request if `input_path` is a
  directory (`translate_document` wraps it in `DeepL::Exceptions::DocumentTranslationError`);
  before, it raised `DeepL::Exceptions::ConnectionError`. Rescue `SystemCallError` for unreadable
  input paths.
- The `glossary` option of document translation requires `source_lang`.
- A `nil` value in `extra_body_parameters` now removes that form field; before, it was sent
  empty.

## Glossaries

`DeepL.glossaries` and `DeepL::GlossaryApi` are removed. `DeepL::Client` has the v2 glossary
methods; for new code, prefer the multilingual glossary methods.

```ruby
# Before (3.x)
glossary = DeepL.glossaries.create('My glossary', 'EN', 'DE', [%w[hello hallo]])
DeepL.glossaries.entries(glossary.id)
DeepL.glossaries.destroy(glossary.id)

# After
glossary = client.create_glossary('My glossary', 'EN', 'DE', { 'hello' => 'hallo' })
client.get_glossary_entries(glossary)   # Hash of source term => target term
client.delete_glossary(glossary)        # returns nil
```

| Removed | Use |
| ------- | --- |
| `DeepL.glossaries.create` | `create_glossary` (entries as a Hash), `create_glossary_from_csv` |
| `.list`, `.find` | `list_glossaries`, `get_glossary` |
| `.entries` (pairs) | `get_glossary_entries` (Hash) |
| `.destroy` (returned the ID) | `delete_glossary` (returns `nil`) |
| `.language_pairs` | `get_glossary_languages` |

The multilingual glossary and spoken terms methods raise `ArgumentError` before any request for
an empty ID, a glossary or spoken terms object without an ID, an empty name, an empty
`source_lang` or `target_lang` of `delete_multilingual_glossary_dictionary`, an empty
`dictionaries` array, and dictionary entries or CSV content that are empty. The multilingual
glossary methods that take a dictionary and `get_multilingual_glossary_dictionary_entries` raise
it for a `nil` or empty `source_lang` or `target_lang`, and the spoken terms methods that take a
language for a `nil` or empty `lang`; before, the request was sent and the API rejected it.

`get_multilingual_glossary_dictionary_entries` raises `DeepL::Exceptions::NotFound` if the
glossary has no dictionary for the language pair. The API answers that with HTTP 404, and the
error has status 404 and the response. If the API answers 200 with no entries instead, the error
now has `http_status_code` `nil` and `response` `nil`; before, it carried status 200 and that
response. Check the error class, not the status.

## Style rules

`DeepL.style_rules` and `DeepL::StyleRuleApi` are removed.

```ruby
# Before (3.x)
rule = DeepL.style_rules.find(rule_id)
rule.configured_rules.numbers

# After
rule = client.get_style_rule(rule_id)
rule.configured_rules.fetch('numbers', {})
```

- Use `get_all_style_rules`, `create_style_rule` and the other style rule methods of
  `DeepL::Client`. They take `source_language:` as a keyword, and the delete methods return
  `nil`.
- `StyleRule#configured_rules` is a Hash with string keys (category, rule, value), as the API
  sends it, not a `ConfiguredRules` object. `DeepL::Resources::ConfiguredRules` is removed.
  Absent categories are no longer filled with `{}`.
- The style rule methods raise `ArgumentError` before any request for an empty ID, a style rule
  or custom instruction without an ID, and an empty name, language, label or prompt. An empty
  `source_language` of `create_style_rule_custom_instruction`,
  `update_style_rule_custom_instruction` or the `custom_instructions` of `create_style_rule`
  raises it too; `nil` still leaves it out.

## Translation memories

`DeepL.translation_memories` and `DeepL::TranslationMemoryApi` are removed. Use the translation
memory methods of `DeepL::Client` (`list_translation_memories`, ...).

- `create_translation_memory_import` and `import_translation_memory_from_filepath` take
  `extra_body_parameters:` instead of `**options`; any other option raises `ArgumentError`.
  ```ruby
  client.import_translation_memory_from_filepath('tm.tmx', extra_body_parameters: { key: 'value' })
  ```
- `download_translation_memory_export(job, output_path)` takes a
  `DeepL::Resources::TranslationMemoryJob` instead of a download URL string. Pass the job
  returned by `wait_until_translation_memory_job_done`.
  ```ruby
  # Before
  client.download_translation_memory_export(job.result.download_url, 'out.tmx')
  # After
  client.download_translation_memory_export(job, 'out.tmx')
  ```
- `download_translation_memory_export` and `export_translation_memory_to_filepath` no longer
  overwrite an existing file. The first raises `Errno::EEXIST`, `Errno::ENOENT` or
  `Errno::EACCES` before the request, and a write failure raises the `Errno` error, so rescue
  `SystemCallError`, not only `DeepL::Exceptions::Error`.
- `import_translation_memory_from_filepath` and `export_translation_memory_to_filepath` wrap
  every failure except a missing input file in the new
  `DeepL::Exceptions::TranslationMemoryJobError` (a `DeepL::Exceptions::Error`), with the
  original error as `cause`, plus `job_id` and `job`. An empty input file raises it too; before,
  it raised `ArgumentError`.
- Methods raise `ArgumentError` instead of `DeepL::Exceptions::Error` for an empty translation
  memory ID or job ID and an empty upload or download URL. `create_translation_memory_import`
  also rejects an empty `file_name` and a `content_length` that is not positive.
- `TranslationMemoryJobResult::STATUS_DOWNLOADED` is removed (the API never sends it); use
  `STATUS_COMPLETED` or `done?`. `TranslationMemoryJob#finished?` is `false` for `downloaded`.
- `create_translation_memory_export` sends no request body (`Content-Length: 0`).

## Usage

`DeepL.usage` is replaced by `Client#get_usage`. The character counters moved into
`usage.character`.

```ruby
# Before (3.x)
usage = DeepL.usage
usage.character_count
usage.character_limit
usage.quota_exceeded?
usage.any_limit_reached?

# After
usage = client.get_usage
usage.character.count
usage.character.limit
usage.character.limit_reached?
usage.any_character_limit_reached?
```

- `any_character_limit_reached?` is `true` if the account's `character` limit or this API key's
  `api_key_character` limit is reached. The speech minutes are not considered; check them with
  `limit_reached?` on the detail.
- `Usage#document` and `Usage#team_document` are removed; the API no longer returns them.

## Errors, validation and retries

- **Network failures** always raise `DeepL::Exceptions::ConnectionError`, with the original
  error as `cause`. The removed module-level API raised the original error.
  ```ruby
  begin
    client.get_usage
  rescue DeepL::Exceptions::ConnectionError => e
    warn e.cause.class
  end
  ```
- **`DeepL::Exceptions::ValidationError` is an `ArgumentError`**, no longer a
  `DeepL::Exceptions::Error`. `rescue DeepL::Exceptions::Error` does not catch it; rescue
  `ArgumentError` to catch every invalid argument.
- **`DeepL::Exceptions::NotSupported`** is removed; nothing raises it.
- **Retries of calls that create a resource.** `create_glossary`, `create_glossary_from_csv`,
  `create_multilingual_glossary`, `create_multilingual_glossary_from_csv`, `create_spoken_terms`,
  `create_style_rule`, `create_style_rule_custom_instruction`, `create_style_profile`, the
  document upload, and the translation memory import and export job creation are retried only
  when the request cannot have been processed: after HTTP 429 and transient network failures
  while connecting, before the request is sent, such as DNS resolution errors, refused
  connections, unreachable hosts or networks, connection timeouts and resets during the TLS or
  proxy handshake. A 5xx reply raises `DeepL::Exceptions::ServerError` with `should_retry?`
  `false` at once. If you retry these calls yourself, check first whether the resource was
  created.
- `AdminClient#create_developer_key` is retried after the same connect failures. Before, it was
  retried only after DNS resolution errors, refused connections and connection timeouts, and
  raised `ConnectionError` at once for the others. Code that retries it itself now sees the
  library's retries first.
- A response body cut off after the headers arrived on such a request, `create_developer_key`
  included, is not retried and raises `ConnectionError` with `should_retry?` `true`, whatever the
  network failure; before, it was `false`. A connection closed before
  the response is still `false`. Check first whether the resource was created.
- **Messages** of `AuthorizationFailed`, `RequestEntityTooLarge`, `LimitExceeded`,
  `QuotaExceeded` and `ServerError` now end with `: <API message>`. Match the start of the
  message or the class, not the exact text.
- `Language#supports_formality?` returns `nil` for a source language; the removed
  `DeepL.languages` raised `NotSupported`.

## Types and signatures

- `AdminClient#set_developer_key_usage_limits` accepts only `characters:`,
  `speech_to_text_milliseconds:` and `speech_to_speech_milliseconds:`; any other keyword raises
  `ArgumentError`. Send other fields with `extra_body_parameters:`.
- Argument types are no longer checked by hand. `app_info:` of a type other than
  `DeepL::AppInfo` or a Hash no longer raises `ArgumentError`, and a glossary entry whose terms
  are not strings (for example `{ 'a' => 1 }`) no longer raises
  `DeepL::Exceptions::ValidationError`; such a value fails as Ruby fails or is sent as its string
  form. Value checks are unchanged. Pass the documented types.
- `Client#translate_document_download`, `#delete_glossary` and the style rule delete methods
  return `nil`.

## Internal classes

These classes were reachable but are not part of the public API. They changed or were removed:

- `DeepL::DocumentApi`, `DeepL::GlossaryApi`, `DeepL::StyleRuleApi`, `DeepL::TranslationMemoryApi`:
  removed; their logic lives in `DeepL::Client`.
- `DeepL::Configuration`: no longer public; the setters are removed.
- `DeepL::API`: now holds the configuration and connection of one client; `#client?` and
  `#update_http_client` are removed.
- `DeepL::Deprecation`: removed.
- `DeepL::Resources::ConfiguredRules`: removed.
