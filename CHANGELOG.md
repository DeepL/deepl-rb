# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Added `DeepL::Resources::DocumentTranslationStatus#done?` (the status is `done`).
- `DeepL::Resources::DocumentHandle.new(document_id, document_key)` creates a handle from a
  stored ID and key; the request and response arguments are now optional.
- `DeepL::Exceptions::DocumentTranslationError` copies `http_status_code` and `should_retry?`
  from the DeepL error it wraps.
- `DeepL::Exceptions::Error.new` accepts the keywords `http_status_code:` and `should_retry:`.
- Added `DeepL::Client#get_usage`, which returns the same `DeepL::Resources::Usage` as
  `DeepL.usage`. Please refer to the README for usage instructions.
- Added translation memories to `DeepL::Client`: `list_translation_memories(page: nil,
  page_size: nil)`, `get_translation_memory(translation_memory)`,
  `delete_translation_memory(translation_memory)`,
  `list_translation_memory_segments(translation_memory, page_size: nil, page_cursor: nil,
  filter_text: nil, filter_case_sensitive: nil)`, `create_translation_memory_import(file_name,
  content_length, content_type: nil, display_name: nil, **options)`,
  `upload_translation_memory_file(translation_memory_import, content, content_type: nil)`,
  `import_translation_memory_from_filepath(input_path, display_name: nil, content_type: nil,
  timeout_s: nil, **options)`, `create_translation_memory_export(translation_memory)`,
  `download_translation_memory_export(job, output_path)`,
  `export_translation_memory_to_filepath(translation_memory, output_path, timeout_s: nil)`,
  `get_translation_memory_job(job)` and `wait_until_translation_memory_job_done(job,
  timeout_s: nil)`. Keywords left `nil` are not sent; the delete and download methods return
  `nil`. Please refer to the README for usage instructions.
- `DeepL.translation_memories.import_from_filepath` accepts `content_type:`, declared in the
  import job and sent with the upload, and `extra_body_parameters:`.
  `DeepL.translation_memories.create_import` accepts `extra_body_parameters:`.
- Added `DeepL::Resources::TranslationMemoryJob#done?` (the status is `completed`) and `#ok?`
  (the status is not `failed` or `expired`, also true while the job runs). `finished?` stays
  true for any terminal status.
- Added style rule lists (`/v3/style_rules`) to `DeepL::Client`:
  `get_all_style_rules(page: nil, page_size: nil, detailed: nil)`,
  `create_style_rule(name, language, configured_rules: nil, custom_instructions: nil,
  **options)`, `get_style_rule(style_rule)`, `update_style_rule_name(style_rule, name,
  **options)`, `update_style_rule_configured_rules(style_rule, configured_rules, **options)`,
  `delete_style_rule(style_rule)`, `create_style_rule_custom_instruction(style_rule, label,
  prompt, source_language: nil, **options)`, `get_style_rule_custom_instruction(style_rule,
  instruction_id)`, `update_style_rule_custom_instruction(style_rule, instruction_id, label,
  prompt, source_language: nil, **options)` and
  `delete_style_rule_custom_instruction(style_rule, instruction_id)`. Keywords left `nil` are
  not sent; the delete methods return `nil`. Please refer to the README for usage
  instructions.
- The style rule operations, in `DeepL::Client` and in `DeepL.style_rules`, take a style rule
  list as its ID or a `DeepL::Resources::StyleRule`, and a custom instruction as its ID or a
  `DeepL::Resources::CustomInstruction`.
- Added the language operations to `DeepL::Client`: `get_source_languages`,
  `get_target_languages`, `get_language_resources` and `get_languages_for_resource(resource,
  include: nil)`. `include:` takes one value or an array and is sent as one `include` query
  parameter per value; without it none is sent. Source and target languages keep their
  upper-case codes; `get_languages_for_resource` returns the codes as the API sends them.
- Added `DeepL::Constants::LanguageResourceName` (`TRANSLATE_TEXT`, `TRANSLATE_DOCUMENT`,
  `GLOSSARY`, `VOICE`, `WRITE`, `STYLE_RULES`, `TRANSLATION_MEMORY`) and
  `DeepL::Constants::LanguageInclude` (`BETA`, `EXTERNAL`). Other strings are still accepted
  and sent unchanged.
- Added document translation to `DeepL::Client`: `translate_document(input_path,
  output_path, source_lang, target_lang, timeout_s: nil, **options)`,
  `translate_document_upload(input_path, source_lang, target_lang, **options)`,
  `translate_document_get_status(handle)`, `translate_document_wait_until_done(handle,
  timeout_s: nil)` and `translate_document_download(handle, output_path)`. The file name is
  the `filename:` option. `translate_document` returns the final status and wraps every
  failure in `DeepL::Exceptions::DocumentTranslationError`; `translate_document_wait_until_done`
  raises `DeepL::Exceptions::Error` with the API's message when the translation fails, and both
  raise when `timeout_s` expires.
- Added `DeepL::Exceptions::DocumentNotReadyError` (a `ServerError`), raised for HTTP 503 on a
  document download.
- Added `DeepL::Exceptions::DocumentTranslationError#document_handle`, the handle of the
  uploaded document (`nil` if the upload failed).
- Added `DeepL::Resources::DocumentTranslationStatus#ok?` (the translation has not failed) and
  `DeepL::Constants::DocumentStatusCode` (`QUEUED`, `TRANSLATING`, `DONE`, `ERROR`).
- Added `DeepL::Client#translate_text(text, source_lang, target_lang, **options)`. It takes
  the options of `DeepL.translate` as keyword arguments and returns one
  `DeepL::Resources::Text` for a string and an array for an array, also for a one-element
  array.
- Added `DeepL::Client#rephrase_text(text, target_lang = nil, writing_style: nil, tone: nil,
  **options)` and `DeepL::Client#correct_text(text, target_lang = nil, **options)`. The
  writing style and tone are keyword arguments, `extra_body_parameters:` is applied last, and
  both return one `DeepL::Resources::Text` for a string and an array for an array, also for a
  one-element array.
- Added `target_language` (`String`) to `DeepL::Resources::Text` for rephrase and correct
  results. It is `nil` for text translation results and when the response does not contain
  it or contains an unexpected value.
- Added the `glossary` option to text translation and document translation
  (`DeepL.document.upload` and `translate_document`). It takes a glossary ID or a
  `DeepL::Resources::Glossary` or `DeepL::Resources::MultilingualGlossary` object and is sent
  as `glossary_id`.
- Added `billed_characters` (`Integer`) and `tag_handling_version` (`String`) to
  `DeepL::Resources::Text` for text translation results. They are `nil` when the response
  does not contain them or contains an unexpected value.
- Added `DeepL::Constants::TagHandlingVersion` (`V1`, `V2`) for the `tag_handling_version`
  option.
- Added `DeepL::Client`, a client instance that owns its configuration and HTTP connection
  and reads no environment variables: `DeepL::Client.new(auth_key, server_url:, headers:,
  max_retries:, timeout:, proxy:, send_platform_info:, app_info:, http_client_options:,
  logger:)`. Its operations follow in later changes. New public types: `DeepL::Client` and
  `DeepL::AppInfo` (`app_name`, `app_version`).
- Added the client options `headers:` (sent with every DeepL API request; a `User-Agent`
  replaces the library's, `Authorization` cannot be replaced), `timeout:` (seconds per
  attempt, default 10, applied to opening, reading and writing) and `proxy:` (a proxy URL,
  also accepted as the `proxy` of `DeepL::HTTPClientOptions`; its user info never shows in
  `inspect` output or error messages). The module configuration has `headers` and `timeout`
  attributes too.
- Added `DeepL::Client.free_account_auth_key?(key)`.
- Added `DeepL::Exceptions::ConnectionError`, raised for network failures without an HTTP
  response (DNS, connection, TLS, timeout) after the retries; the original exception is its
  `cause`.
- Added `http_status_code` (`Integer`, `nil` without a response) to
  `DeepL::Exceptions::Error`. `RequestError#request` now returns the failed request, and the
  message of a `RequestError` for an unmapped status contains the status and the API's
  message instead of `Unknown error.`.
- Added the `style_profile` option to text translation (`DeepL.translate`) and document
  translation (`DeepL.document.upload` and `translate_document`). It takes a style profile
  ID string or a `DeepL::Resources::StyleProfile` object and is sent as `style_profile_id`.
- Added support for style profiles (`/v3/style_profiles`) to `DeepL::Client`:
  `create_style_profile(name, **options)`, `list_style_profiles(page:, page_size:)`,
  `get_style_profile(style_profile)`, `update_style_profile(style_profile, **options)` and
  `delete_style_profile(style_profile)` (returns `nil`). A style profile links glossaries,
  style rule lists and translation memories; it is given as its ID or a
  `DeepL::Resources::StyleProfile`, whose ID is `style_profile_id`. The component lists
  (`glossary_ids`, `style_rule_ids`, `translation_memory_ids`) take IDs or the
  `Glossary`, `MultilingualGlossary`, `StyleRule` and `TranslationMemory` objects, which are
  sent as their IDs. In create and update, keywords left `nil` are not sent; an empty string
  clears `description` or `industry`, and an empty array unlinks all components of that
  kind. Please refer to the README for usage instructions.
- Added support for spoken terms collections (`/v3/spoken-terms`) to `DeepL::Client`:
  `create_spoken_terms(name, term_lists, **options)`, `list_spoken_terms`,
  `get_spoken_terms(spoken_terms)`, `update_spoken_terms(spoken_terms, name:, term_lists:,
  **options)`, `delete_spoken_terms(spoken_terms)`, `get_spoken_terms_entries(spoken_terms,
  lang)`, `replace_spoken_terms_list(spoken_terms, entries, **options)` and
  `delete_spoken_terms_list(spoken_terms, lang)`. A collection is given as its ID or a
  `DeepL::Resources::SpokenTerms` (`spoken_terms_id`, `name`, `creation_time`, `term_lists`);
  the terms of a language as a `DeepL::Resources::SpokenTermsEntries` or a hash with `:lang`
  and `:entries`. Terms are arrays of strings and are stripped and checked like glossary terms
  before they are sent. The delete methods return `nil`. Please refer to the README for usage
  instructions. Collection IDs are URL-encoded in the request paths. `creation_time` is a UTC
  `Time` when the timestamp has no offset and `nil` when it is malformed.
- Added `DeepL::AdminClient` for the Admin API. It must be created with an admin
  API key, accepts the options of `DeepL::Client` and supports managing developer keys
  (`create_developer_key(label: nil)`, `list_developer_keys`, `deactivate_developer_key`,
  `rename_developer_key`, `set_developer_key_usage_limits`) and retrieving usage analytics
  (`get_usage_analytics`, `get_custom_tag_usage_analytics`). The four methods that send a
  body accept `extra_body_parameters:`, added to the request body last.
  `DeveloperKey#label`, `DeveloperKey#usage_limits`, `KeyUsage#api_key_label`,
  `AdminUsageReport#total_usage`, `#start_date`, `#end_date` and
  `AdminUsageBreakdown#speech_to_speech_minutes` and
  `CustomTagUsageBreakdown#speech_to_speech_minutes` are `nil` when the response does not
  contain them.
  `set_developer_key_usage_limits` changes only the given limits, including
  `speech_to_speech_milliseconds`. New public types: `DeepL::AdminClient`,
  `DeepL::Resources::DeveloperKey`, `DeepL::Resources::DeveloperKeyUsageLimits`,
  `DeepL::Resources::AdminUsageReport`, `DeepL::Resources::AdminUsageBreakdown`,
  `DeepL::Resources::KeyUsage`, `DeepL::Resources::CustomTagUsageReport`,
  `DeepL::Resources::CustomTagUsageBreakdown`, `DeepL::Resources::CustomTagUsage`,
  `DeepL::Constants::AdminUsageGroupBy` and `DeepL::Constants::CustomTagUsageAggregateBy`.
  The usage breakdown includes `speech_to_speech_minutes`.
- Added support for multilingual glossaries (`/v3/glossaries`) to `DeepL::Client`:
  `create_multilingual_glossary(name, dictionaries, **options)`,
  `create_multilingual_glossary_from_csv(name, source_lang, target_lang, csv, **options)`,
  `list_multilingual_glossaries`, `get_multilingual_glossary(glossary)`,
  `update_multilingual_glossary(glossary, name: nil, dictionaries: nil, **options)` (sends
  only the keywords given, `{}` without any), `update_multilingual_glossary_name`,
  `update_multilingual_glossary_dictionary(glossary, dictionary, **options)`,
  `update_multilingual_glossary_dictionary_from_csv`,
  `replace_multilingual_glossary_dictionary(glossary, dictionary, **options)`,
  `replace_multilingual_glossary_dictionary_from_csv`,
  `get_multilingual_glossary_dictionary_entries(glossary, source_lang, target_lang)`,
  `delete_multilingual_glossary_dictionary(glossary, source_lang, target_lang)` and
  `delete_multilingual_glossary(glossary)`. A glossary is given as its ID or a
  `DeepL::Resources::MultilingualGlossary`; the ID is URL-encoded in the request paths. A
  dictionary is a `DeepL::Resources::MultilingualGlossaryDictionaryEntries` (`source_lang`,
  `target_lang` and `entries` as source/target pairs, constructible with `.new`) or a hash
  with the same keys. `get_multilingual_glossary_dictionary_entries` returns one dictionary
  and raises `DeepL::Exceptions::NotFound` if the glossary has none for the language pair;
  the delete methods return `nil`. `creation_time` is a UTC `Time`, `nil` when malformed.
  The module-level `DeepL.multilingual_glossaries` (`create`, `create_with_csv`, `find`,
  `list`, `entries`, `destroy`, `destroy_dictionary`, `replace_dictionary`,
  `replace_dictionary_with_csv`, `update_name`, `update_dictionary` and
  `update_dictionary_with_csv`) sends the same requests and returns the same objects. Please
  refer to the README for usage instructions.
- Added `DeepL.correct(text, target_lang = nil)` to correct grammar and spelling via
  `POST /v2/write/correct`. It accepts a string or an array of strings and returns a
  `DeepL::Resources::Text` or an array of them, respectively.
- Added `DeepL.languages_for_resource` (`GET /v3/languages`), which returns the
  languages supported by a given resource as `DeepL::Resources::LanguageSupport`
  objects with source/target usability, status and per-feature support. The
  `include` option (`beta`, `external`) also returns beta or third-party-backed
  languages and features.
- Added `DeepL.language_resources` (`GET /v3/languages/resources`), which returns
  each resource (`name`) and its features as `DeepL::Resources::LanguageResource` objects,
  including whether a feature needs source and/or target language support.
- Added the `enable_watermark` option to `DeepL.document.upload` and
  `DeepL.document.translate_document`. When `true`, the API adds a "Translated by DeepL"
  watermark to `docx` and `pdf` output. Previously the option was silently dropped.
- `DeepL.usage` now returns each usage type as a `DeepL::Resources::Usage::Detail` (`count`,
  `limit`, `limit_reached?`), like the other DeepL client libraries: `character`, `document`,
  `team_document`, and for API Pro users `api_key_character`, `speech_to_text_minutes` and
  `speech_to_speech_minutes`. API Pro users also get `start_time` and `end_time` (as `Time`)
  and `products` (an array of `DeepL::Resources::UsageProduct`). Fields missing from the
  response are `nil`. The new `any_limit_reached?` checks the character, document and team
  document limits, not the API Pro ones. `character_count`, `character_limit`,
  `quota_exceeded?` and `to_s` are unchanged.

### Changed
- Text translation accepts a glossary without a source language: the `glossary_ids`
  option no longer requires `source_lang`, and the API detects the source language.
  Document translation with `glossary_ids` still requires `source_lang`.
- `DeepL.document.translate_document` now returns the final
  `DeepL::Resources::DocumentTranslationStatus`, as documented, instead of the number of bytes
  written.
- Text translation now always sends `show_billed_characters: true`, so every result has
  `billed_characters`.
- Network failures are now raised as `DeepL::Exceptions::ConnectionError` after the retries,
  instead of the raw `SocketError`, `Timeout::Error`, `Errno::*` or `OpenSSL::SSL::SSLError`.
- Requests now time out after 10 seconds per attempt (or the backoff interval, if longer)
  instead of Net::HTTP's 60 seconds; set `timeout:` (or `config.timeout`) to change it.
  Timeouts given in `DeepL::HTTPClientOptions` still take precedence.
- `DeepL.languages` and `DeepL.glossaries.language_pairs` now use the `GET /v3/languages`
  endpoint instead of the deprecated `GET /v2/languages` and `GET /v2/glossary-language-pairs`
  endpoints. Public method signatures and return types are unchanged. An unsupported `type`
  option passed to `DeepL.languages` now raises `ArgumentError` instead of
  `DeepL::Exceptions::BadRequest`, since the value is now validated client-side.
- Language lists returned by `DeepL.languages` and `DeepL.glossaries.language_pairs` may now
  include additional languages that the v2 endpoints did not list.
- `import_translation_memory_from_filepath` (and `DeepL.translation_memories.import_from_filepath`)
  raises `ArgumentError` instead of `DeepL::Exceptions::Error` when the input file does not
  exist, before any request is sent.
- `export_translation_memory_to_filepath` (and `DeepL.translation_memories.export_to_filepath`)
  raises `DeepL::Exceptions::Error` before creating the export job if the output directory does
  not exist.
- Reworked the test suite so that it no longer needs the `deepl-mock` server. The offline specs
  assert the exact outgoing requests with WebMock, and one real-API spec per resource calls each
  endpoint once. `webmock` and `webrick` are test dependencies again.

### Deprecated
- `DeepL::Resources::DocumentTranslationStatus#successful?`, use `#done?` instead. It prints a
  warning once per process and keeps working unchanged.
- `DeepL::Resources::Usage#character_count`, `#character_limit` and `#quota_exceeded?`, use
  `character.count`, `character.limit` and `character.limit_reached?` (or
  `any_limit_reached?`) instead. Each prints a warning once per process and keeps working
  unchanged. `DeepL.usage` now names `DeepL::Client#get_usage` as its replacement.
- The methods of `DeepL::TranslationMemoryApi` (`DeepL.translation_memories`), use the
  translation memory methods of `DeepL::Client` instead (`list` is
  `list_translation_memories`, `find` is `get_translation_memory`, `segments` is
  `list_translation_memory_segments`, `find_job` is `get_translation_memory_job`, and so on).
  They keep working unchanged.
- The methods of `DeepL::StyleRuleApi` (`DeepL.style_rules`), use the style rule methods of
  `DeepL::Client` instead (`list` is `get_all_style_rules`, `find` is `get_style_rule`,
  `update_name` is `update_style_rule_name`, `destroy` is `delete_style_rule`, and so on).
  They keep working unchanged.
- `DeepL::Exceptions::NotSupported` is deprecated: the library no longer raises it. Creating
  one prints a deprecation warning once per process.
- The module-level API is deprecated in favour of `DeepL::Client` and will be removed in the
  next major version: `DeepL.configure`, `DeepL.configuration`, `DeepL.api`, `DeepL.translate`,
  `DeepL.rephrase`, `DeepL.correct`, `DeepL.usage`, `DeepL.languages`,
  `DeepL.languages_for_resource`, `DeepL.language_resources`, `DeepL.document`,
  `DeepL.glossaries`, `DeepL.multilingual_glossaries`, `DeepL.style_rules`,
  `DeepL.translation_memories`,
  `DeepL.with_session` and `DeepL.http_client`. Each prints a warning once per process and
  keeps working unchanged.
- `DeepL::Configuration#version=` (the API version is part of each endpoint).
- The `glossary_id` option of text and document translation, use `glossary` instead. It
  prints a warning once per process and keeps working unchanged.
- `DeepL::Resources::DocumentHandle#wait_until_document_translation_finished`, use
  `DeepL::Client#translate_document_wait_until_done` instead.
- `DeepL::Configuration#max_doc_status_queries=`, use the `timeout_s:` of
  `DeepL::Client#translate_document` or `translate_document_wait_until_done` instead.

### Fixed
- `get_usage` (and `DeepL.usage`), the glossary and multilingual glossary get, list, entries
  and delete requests, and the style rule and custom instruction get and delete requests sent a
  JSON body `{}` with `Content-Type: application/json`. GET and DELETE requests are now sent
  without a body.
- A response body shorter than its `Content-Length` (the connection closed mid-body) was
  returned as complete: `translate_document_download` wrote a truncated document, and JSON
  calls raised a generic "Unexpected response" error. It is now retried like a reset
  connection and, after the last retry, raises `DeepL::Exceptions::ConnectionError` with
  `should_retry?` true.
- An HTTPS proxy that refuses the `CONNECT` request (for example with 407 Proxy Authentication
  Required) raised a raw `Net::HTTPClientException` or `Net::HTTPFatalError`. It now raises
  `DeepL::Exceptions::ConnectionError` with `should_retry?` false, without retrying.
- Headers passed per call to the module-level API (`DeepL.translate`, `DeepL.rephrase`,
  `DeepL.correct`, `DeepL.document` and `DeepL.translation_memories.create_import`) could
  replace the `Authorization` header. An `Authorization` header in any casing is now ignored, as
  in `headers:`.
- Net::HTTP re-sent a failed GET, PUT or DELETE request once on its own, so with
  `max_retries: 0` such a request could still be sent twice. The library's connections now
  disable Net::HTTP's own retry; only `max_retries:` applies.
- TLS failures (including certificate verification failures) and malformed HTTP responses were
  retried like transient network failures. They now raise `DeepL::Exceptions::ConnectionError`
  at once, with `should_retry?` false.
- Query values were encoded with a space as `+`. They are now encoded per RFC 3986, with a space
  as `%20`.
- `DeepL::Client#translate_document` and `DeepL.document.translate_document` raise
  `DeepL::Exceptions::DocumentTranslationError` (without a document handle) instead of
  `IOError` when the output file already exists; the file is still kept and nothing is
  uploaded. The doc comment of `DeepL.document.translate_document` no longer claims that an
  existing file is overwritten.
- `DeepL::Client#translate_document` raises `ArgumentError` for a missing input file before
  any request, instead of wrapping the `Errno::ENOENT` in `DocumentTranslationError`.
- Multilingual glossary entries given as a TSV string are parsed into pairs, and each term is
  stripped and checked like terms given as pairs, before anything is sent. A line that is not
  exactly two tab-separated terms raises `ArgumentError`. CSV content is still sent as given.
- A non-2xx reply of a pre-signed translation memory storage URL (upload or export download)
  raised the error class of the DeepL API status, for example `AuthorizationFailed` asking for a
  valid `auth_key` for an expired URL (403). It now raises a plain `DeepL::Exceptions::Error`
  with `http_status_code`; `should_retry?` is true for 429 and 5xx.
- The translation memory file helpers raised raw `Errno::*` and `IOError` errors for local file
  failures, such as an input path that is a directory or unreadable, or an output path that
  cannot be written. They now raise `DeepL::Exceptions::Error` with the original error as
  `cause`.
- `wait_until_translation_memory_job_done` (and the file helpers) could wait up to five seconds
  past `timeout_s`; the last wait is now cut to the deadline.
- Uploads to and downloads from the pre-signed translation memory storage URLs ignored the
  proxy, SSL verification, certificate file and timeouts set with `proxy:` or
  `http_client_options:` (or `DeepL.with_session`). They now use the same options as the API
  connection, still without the `Authorization` header.
- A malformed timestamp in a translation memory, segment, import or job response raised a raw
  `ArgumentError`, and a timestamp without a zone offset was read as local time. A malformed
  timestamp is now `nil`, and one without an offset is read as UTC.
- `DeepL.translation_memories.list` and `segments` sent an option set to `nil` as an empty
  query parameter (`page=`). Such options are no longer sent.
- Translation memory and job IDs were inserted into the request path without URL encoding:
  an ID containing `/` changed the path and a space raised `URI::InvalidURIError`. They are
  now URL-encoded.
- Style rule list and custom instruction IDs were inserted into the request path without
  URL encoding: an ID containing `/` changed the path and a space raised
  `URI::InvalidURIError`. They are now URL-encoded.
- A malformed `creation_time` or `updated_time` of a style rule list raised a raw
  `ArgumentError`. It now raises `DeepL::Exceptions::Error`.
- Creating a style rule list removed `configured_rules` and `custom_instructions` from the
  options hash passed in, so reusing the hash for another create sent neither. The hash is no
  longer changed.
- `DeepL::Resources::Language#supports_formality?` raised `DeepL::Exceptions::NotSupported`
  for source languages. It now returns `nil` for them.
- `DeepL.document.translate_document` and `DocumentHandle#wait_until_document_translation_finished`
  stopped polling after 11 status requests (about 50 seconds), and `translate_document` then
  downloaded the unfinished document. They now poll until the translation is done or failed;
  only an explicitly configured `max_doc_status_queries` still limits the requests, and
  `translate_document` then raises `DocumentTranslationError` instead of downloading.
- Downloaded documents were written in text mode, which converted newlines on Windows and
  failed or transcoded the bytes when `Encoding.default_internal` was set. They are now
  written in binary mode.
- Document IDs are now URL-encoded in the status and download paths.
- Text translation sent options set to `nil`, and a `nil` source language, as JSON `null`.
  They are now treated as unset and not sent.
- `translation_memory: nil` sent an empty `translation_memory_id`, and
  `translation_memory_threshold: nil` sent `null` (text) or an empty field (documents). Both
  are now treated as unset and not sent.
- Document translation (`DeepL.document.upload` and `translate_document`) treated an option
  set to `nil` as set: `glossary_ids` with `glossary_id: nil` raised `ArgumentError`. Options
  set to `nil` are now treated as unset and not sent, as in text translation.
- A `custom_instructions` string was split at commas into several instructions. It is now
  sent as one instruction.
- `DeepL.configure { |c| c.auth_key = '...:fx' }` kept `https://api.deepl.com`, because the
  default server was chosen before the block set the key. Without a configured host, the
  server is now chosen from the final key.
- A Free key with surrounding whitespace (`'abc:fx '`) selected `https://api.deepl.com`
  although the trimmed key was sent. The Free check now trims the key too.
- The auth key was sent with surrounding whitespace, and a whitespace-only key passed
  `DeepL.configure`. The key is now trimmed, and a blank key raises
  `DeepL::Exceptions::Error`.
- Only HTTP 429 and 500 replies were retried; 502, 503, 504 and other 5xx replies were raised
  immediately. Every 5xx reply is now retried.
- Refused or reset connections, `EOFError` and TLS errors were not retried. They are now
  retried like timeouts and DNS failures. `AdminClient#create_developer_key` also retries a
  refused connection, which shows that the request was not sent.
- A malformed response (invalid JSON or an unexpected structure) raised `JSON::ParserError`,
  `NoMethodError` or `TypeError`. It now raises `DeepL::Exceptions::Error`. A 400 or 404
  reply with a JSON array body raised `TypeError` when its message was read.
- `extra_body_parameters` were overridden by options of the same name, and a string key next
  to the SDK's symbol key sent the field twice. They are now applied last and replace the
  SDK's field.
- `DeepL.with_session` turned TLS off (instead of certificate verification) when
  `enable_ssl_verification` was `false`, turned it on for `http://` hosts, and used a proxy
  with only an address. It now builds its connection like `DeepL::AdminClient`.
- `DeepL.with_session` opened its connection with Net::HTTP's 60 second open timeout and
  raised DNS, connection and TLS failures raw. It now uses the configured `timeout` unless
  the HTTP client options set `open_timeout`, and raises `DeepL::Exceptions::ConnectionError`.
- `DocumentHandle#wait_until_document_translation_finished` polled through the module
  configuration instead of the connection that created the handle.
- `DeepL::Configuration#inspect` showed the auth key. It now shows `[REDACTED]`.
- Glossary entries given as `[source, target]` pairs (`DeepL.glossaries.create` and the
  `DeepL.multilingual_glossaries` methods) were sent unchecked, so a term with a tab or newline
  silently corrupted the entries. Each term is now stripped of surrounding whitespace and sent
  stripped; an invalid term raises `ArgumentError` before any request: it must not be empty or
  contain C0 or C1 control characters, U+2028 or U+2029. Entries given as a TSV or CSV string
  are still sent as given.
- Debug logging no longer includes the auth key in the logged request headers.
- Network errors (timeouts, `SocketError`) were retried without limit. They are now retried at
  most `max_network_retries` times, like 429 and 500 replies, and then raised.
- `DeepL.document.translate_document` raised `NoMethodError` instead of `IOError` when the output
  file already exists. It now raises `IOError` and leaves the file untouched.
- `DeepL.with_session` without client options raised `ArgumentError`, and without a block raised
  `NoMethodError`. It now runs with default options and raises `ArgumentError` without a block.
  `HTTPClientOptions.new` now defaults `proxy` to `{}` and `cert_path` to `nil`, so the README
  example `HTTPClientOptions.new({ 'proxy_addr' => ..., 'proxy_port' => ... })` works.
- `DeepL.with_session` left its HTTP client, including the proxy, in place after the block, so
  every later call went through a closed client and the proxy. It now restores the previous
  client when the block ends or raises.
- A failed `translate_document` raised `NameError` instead of
  `DeepL::Exceptions::DocumentTranslationError` when nothing else had loaded `fileutils`. The
  library now requires it.
- An option set to `false` with a string key (for example `'split_sentences' => false`) was read as
  unset, so its conversion was skipped and `false` was sent instead of the API value `'0'`.
- Document translation (`DeepL.document.upload` and `translate_document`) with source language
  `nil` raised `TypeError` before sending the request. It now omits `source_lang`, so the API
  detects the language of the document.
- `style_rule: nil` sent an empty `style_id` in text and document translation. A `nil` style rule
  is now treated as unset and sends nothing.
- `DeepL.rephrase` returned fewer results than texts, or `nil` for a string, when the response
  contained fewer improvements than texts. It now raises `DeepL::Exceptions::Error`.

## [3.9.0] - 2026-08-11
### Added
- Added support for using multiple glossaries in text and document translation
  via the `glossary_ids` option (up to 5 glossary IDs) in `translate` and
  document upload.
- Added support for using a style rule in document translation via the
  `style_id` option (the `style_rule` option) in document upload.
- Added support for using a translation memory in document translation via the
  `translation_memory_id` option (the `translation_memory` and
  `translation_memory_threshold` options) in document upload.
- Added support for translation memory management via `DeepL.translation_memories`:
  `find()`, `segments()`, `destroy()`, `create_import()`, `upload_file()`,
  `create_export()`, `find_job()`, `wait_until_job_done()`, `download_export()`,
  and the convenience methods `import_from_filepath()` and `export_to_filepath()`.
  Every method taking a translation memory accepts a string ID or a
  `TranslationMemory` object. `wait_until_job_done()`, `import_from_filepath()`
  and `export_to_filepath()` accept an optional `timeout_s` to stop waiting for
  a job that does not finish. Please refer to the README for usage instructions.
- Added the `creation_time` and `updated_time` attributes to `TranslationMemory`.

### Changed
- Reworked the test suite to run against the `deepl-mock` server with OpenAPI
  request and response validation enabled in CI, replacing recorded VCR
  cassettes. Added live integration and error-path specs across all endpoints,
  with resource-level unit specs for response field mapping.

### Removed
- Dropped VCR cassette playback and the `vcr` and `webmock` development
  dependencies.

## [3.8.0] - 2026-05-27
### Added
- Added support for passing additional HTTP headers to `translate()` and
  `rephrase()`. This can be used to send the `X-DeepL-Reporting-Tag` header
  for usage reporting.

## [3.7.0] - 2026-05-14
### Added
- Added support for listing translation memories via `DeepL.translation_memories.list`.
- Added `translation_memory` and `translation_memory_threshold` parameters to `translate()`
  to use a translation memory during text translation. The `translation_memory` parameter
  accepts a string ID or a `TranslationMemory` object.
- Added support for style rules CRUD operations via `DeepL.style_rules`:
  `create()`, `find()`, `update_name()`, `update_configured_rules()`, and `destroy()`.
- Added support for style rule custom instruction CRUD operations via `DeepL.style_rules`:
  `create_custom_instruction()`, `find_custom_instruction()`,
  `update_custom_instruction()`, and `destroy_custom_instruction()`.
  Please refer to the README for usage instructions.

### Changed
- Updated unit test to expect the `model_type_used` to now be `quality_optimized`
- Set explicit `image` for `gitlab release` CI job to avoid missing `$HOME` issues

## [3.6.1] - 2025-12-19
### Fixed
- Fixed broken 3.6.0 release

## [3.6.0] - 2025-12-10
### Added
- Added `tag_handling_version` parameter to `translate()` to specify which version of the tag handling algorithm to use. Options are `v1` and `v2`.

### Fixed
- `extra_body_parameters` will no longer cast values to string, as this library sends JSON-encoded requests
  (allows e.g. sending booleans)

## [3.5.1] - 2025-12-19
### Fixed
- Fixed broken 3.5.0 release

## [3.5.0] - 2025-12-03
### Added
- Added `custom_instructions` parameter to `translate()` to customize translation
  behavior with up to 10 instructions (max 300 characters each). Only supported for
  target languages: `de`, `en`, `es`, `fr`, `it`, `ja`, `ko`, `zh` and their variants.
  Note: using the `custom_instructions` parameter will use the `quality_optimized`
  model type as the default. Requests combining `custom_instructions` and the
  `latency_optimized` model type will be rejected.

## [3.4.1] - 2025-12-19
### Fixed
- Fixed broken 3.4.0 release

## [3.4.0] - 2025-11-17
### Added
- Added support for the `GET /v3/style_rules` endpoint in the client library, the
  implementation can be found in the `StyleRuleApi` class. Please refer to the
  README for usage instructions
- Added `style_id` option to `translate()` which allows text translation with
  style rules.

### Fixed
- Send correct library version in user-agent. Expose library version in the module as a variable.

## [3.3.0] - 2025-11-04
### Added
- Added `extra_body_parameters` option to text and document translation methods to pass arbitrary parameters in the request body. This can be used to access beta features or override built-in parameters (such as `target_lang`, `source_lang`, etc.).
- Added `rephrase` functionality to the top-level `DeepL` module for convenience.
  * Thanks to [341bms](https://github.com/341bms) in [#14](https://github.com/DeepL/deepl-rb/issues/14) for the report!

## [3.2.0] - 2025-01-15
### Added
- Added `rephrase` functionality to get a new version of submitted text with various possible styles or tones applied
- Added `DeepL::Constants` namespace and associated constant values for options possibilities

## [3.1.0] - 2024-11-15
### Added
- Added `model_type` option to `translate()` to use models with higher
  translation quality (available for some language pairs), or better latency.
  Options are `'quality_optimized'`, `'latency_optimized'`, and  `'prefer_quality_optimized'`
- Added the `model_type_used` field to the `translate()` response, that
  indicates the translation model used when the `model_type` option is
  specified.

## [3.0.2] - 2024-10-02
### Added
- Added doc example and tests for context parameter

### Fixed
- Fix metadata displayed on RubyGems.org for this library.
- Fixed library version sent in the `User-Agent` string.

## [3.0.1] - 2024-09-23
### Fixed
- `document.translate_document` required a filename, this is now optional. The example in the README now works.

## [3.0.0] - 2024-09-20
Beginning with version 3, deepl-rb is officially supported by DeepL, and maintained together with [Daniel Herzog](mailto:info@danielherzog.es) the developer of earlier versions of this library.
The change in major version is only due to the change in maintainership, there is no migration necessary from v2 to v3.

### Added
- Added rubocop-rspec linting for rspec test files
- Added document translation to the ruby CL
- Added possibility to use one HTTP session for multiple calls
- Added platform and ruby version information to the user-agent string that is sent with API calls, along with an opt-out
- Added support for logging of HTTP requests
- Added support for using a proxy and a custom certificate file
- Added a gitlab CI pipeline

### Changed
- HTTP requests to the DeepL API now use `application/json`, rather than `application/www-form-unencoded`
- HTTP requests now automatically retry on transient failures, using exponential backoff

### Removed
- Removed CircleCI and CodeCov upload

## [2.5.3] - 2022-09-26
### Fixed
- Make RequestEntityTooLarge error message more clear

[Unreleased]: https://github.com/DeepL/deepl-rb/compare/v3.9.0...HEAD
[3.9.0]: https://github.com/DeepL/deepl-rb/compare/v3.8.0...v3.9.0
[3.8.0]: https://github.com/DeepL/deepl-rb/compare/v3.7.0...v3.8.0
[3.7.0]: https://github.com/DeepL/deepl-rb/compare/v3.6.1...v3.7.0
[3.6.1]: https://github.com/DeepL/deepl-rb/compare/v3.6.0...v3.6.1
[3.6.0]: https://github.com/DeepL/deepl-rb/compare/v3.5.1...v3.6.0
[3.5.1]: https://github.com/DeepL/deepl-rb/compare/v3.5.0...v3.5.1
[3.5.0]: https://github.com/DeepL/deepl-rb/compare/v3.4.1...v3.5.0
[3.4.1]: https://github.com/DeepL/deepl-rb/compare/v3.4.0...v3.4.1
[3.4.0]: https://github.com/DeepL/deepl-rb/compare/v3.3.0...v3.4.0
[3.3.0]: https://github.com/DeepL/deepl-rb/compare/v3.2.0...v3.3.0
[3.2.0]: https://github.com/DeepL/deepl-rb/compare/v3.1.0...v3.2.0
[3.1.0]: https://github.com/DeepL/deepl-rb/compare/v3.0.2...v3.1.0
[3.0.2]: https://github.com/DeepL/deepl-rb/compare/v3.0.1...v3.0.2
[3.0.1]: https://github.com/DeepL/deepl-rb/compare/v3.0.0...v3.0.1
[3.0.0]: https://github.com/DeepL/deepl-rb/compare/v2.5.3...v3.0.0
[2.5.3]: https://github.com/DeepL/deepl-rb/releases/tag/v2.5.3
