# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Added support for multilingual glossaries via the v3 glossary API.
  `DeepL.multilingual_glossaries` exposes `create`, `create_with_csv`, `find`,
  `list`, `entries`, `destroy`, `destroy_dictionary`, `replace_dictionary`,
  `replace_dictionary_with_csv`, `update_name`, `update_dictionary`, and
  `update_dictionary_with_csv`. Please refer to the README for usage
  instructions.
- Added `DeepL.correct(text, target_lang = nil)` to correct grammar and spelling via
  `POST /v2/write/correct`. It accepts a string or an array of strings and returns a
  `DeepL::Resources::Text` or an array of them, respectively.
- Added `DeepL.languages_for_resource` (`GET /v3/languages`), which returns the
  languages supported by a given resource as `DeepL::Resources::LanguageSupport`
  objects with source/target usability, status and per-feature support. The
  `include` option (`beta`, `external`) also returns beta or third-party-backed
  languages and features.
- Added `DeepL.language_resources` (`GET /v3/languages/resources`), which returns
  each resource and its features as `DeepL::Resources::LanguageResource` objects,
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
- `DeepL.languages` and `DeepL.glossaries.language_pairs` now use the `GET /v3/languages`
  endpoint instead of the deprecated `GET /v2/languages` and `GET /v2/glossary-language-pairs`
  endpoints. Public method signatures and return types are unchanged. An unsupported `type`
  option passed to `DeepL.languages` now raises `ArgumentError` instead of
  `DeepL::Exceptions::BadRequest`, since the value is now validated client-side.
- Language lists returned by `DeepL.languages` and `DeepL.glossaries.language_pairs` may now
  include additional languages that the v2 endpoints did not list.
- Reworked the test suite so that it no longer needs the `deepl-mock` server. The offline specs
  assert the exact outgoing requests with WebMock, and one real-API spec per resource calls each
  endpoint once. `webmock` and `webrick` are test dependencies again.

### Fixed
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
