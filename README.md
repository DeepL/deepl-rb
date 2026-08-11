[![Gem Version](https://badge.fury.io/rb/deepl-rb.svg)](https://badge.fury.io/rb/deepl-rb)

# DeepL Ruby Library

The [DeepL API](https://developers.deepl.com/docs/api-reference/translate) is a language translation API that allows other computer programs to send texts and documents to DeepL's servers and receive high-quality translations. This opens a whole universe of opportunities for developers: any translation product you can imagine can now be built on top of DeepL's best-in-class translation technology.

The DeepL Ruby library offers a convenient way for applications written in Ruby to interact with the DeepL API. We intend to support all API functions with the library, though support for new features may be added to the library after they’re added to the API.

## Getting an authentication key

To use the DeepL Ruby Library, you'll need an API authentication key. To get a key, [please create an account here](https://www.deepl.com/pro?utm_source=github&utm_medium=github-ruby-readme#developer). With a DeepL API Free account you can translate up to 500,000 characters/month for free.

## Installation

Install this gem with

```sh
gem install deepl-rb
# Load it in your ruby file using `require 'deepl'`
```

Or add it to your Gemfile:

```rb
gem 'deepl-rb', require: 'deepl'
```

## Usage

Setup an environment variable named `DEEPL_AUTH_KEY` with your authentication key:

```sh
export DEEPL_AUTH_KEY="your-api-token"
```

Alternatively, you can configure the API client within a ruby block:

```rb
DeepL.configure do |config|
  config.auth_key = 'your-api-token'
end
```

You can also configure the API host and the API version:

```rb
DeepL.configure do |config|
  config.auth_key = 'your-api-token'
  config.host = 'https://api-free.deepl.com' # Default value is 'https://api.deepl.com'
  config.version = 'v1' # Default value is 'v2'
end
```

### Available languages

Available languages can be retrieved via API:

```rb
languages = DeepL.languages

puts languages.class
# => Array
puts languages.first.class
# => DeepL::Resources::Language
puts "#{languages.first.code} -> #{languages.first.name}"
# => "ES -> Spanish"
```

Note that source and target languages may be different, which can be retrieved by using the `type`
option:

```rb
puts DeepL.languages(type: :source).count
# => 24
puts DeepL.languages(type: :target).count
# => 26
```

All languages are also defined on the
[official API documentation](https://developers.deepl.com/docs/api-reference/translate).

Note that target languages may include the `supports_formality` flag, which may be checked
using the `DeepL::Resources::Language#supports_formality?`.

### Translate

To translate a simple text, use the `translate` method:

```rb
translation = DeepL.translate 'This is my text', 'EN', 'ES'

puts translation.class
# => DeepL::Resources::Text
puts translation.text
# => 'Este es mi texto'
```

Enable auto-detect source language by skipping the source language with `nil`:

```rb
translation = DeepL.translate 'This is my text', nil, 'ES'

puts translation.detected_source_language
# => 'EN'
```

Translate a list of texts by passing an array as an argument:

```rb
texts = ['Sample text', 'Another text']
translations = DeepL.translate texts, 'EN', 'ES'

puts translations.class
# => Array
puts translations.first.class
# => DeepL::Resources::Text
```

You can also use custom query parameters, like `tag_handling`, `split_sentences`, `non_splitting_tags` or `ignore_tags`:

```rb
translation = DeepL.translate '<p>A sample</p>', 'EN', 'ES',
                              tag_handling: 'xml', split_sentences: false,
                              non_splitting_tags: 'h1', ignore_tags: %w[code pre]

puts translation.text
# => "<p>Una muestra</p>"
```

To specify which version of the tag handling algorithm to use, you can use the `tag_handling_version` parameter:

```rb
translation = DeepL.translate '<p>A sample</p>', 'EN', 'ES',
                              tag_handling: 'xml', tag_handling_version: 'v2'

puts translation.text
# => "<p>Una muestra</p>"
```

The available values are `'v1'` and `'v2'`.

To translate with context, simply supply the `context` parameter:

```rb
translation = DeepL.translate 'That is hot!', 'EN', 'ES',
                              context: 'He did not like the jalapenos in his meal.'

puts translation.text
# => "¡Eso es picante!"
```

To specify a type of translation model to use, you can use the `model_type` option:

```rb
translation = DeepL.translate 'That is hot!', 'EN', 'DE',
                              model_type: 'quality_optimized'
```

This would use next-gen translation models for the translation. The available values are

- `'quality_optimized'`: use a translation model that maximizes translation quality, at the
  cost of response time. This option may be unavailable for some language pairs.
- `'prefer_quality_optimized'`: use the highest-quality translation model for the given
  language pair.
- `'latency_optimized'`: use a translation model that minimizes response time, at the cost
  of translation quality.

To translate with custom instructions, supply the `custom_instructions` parameter:

```rb
translation = DeepL.translate 'Hello, world!', 'EN', 'DE',
                              custom_instructions: ['Use informal language', 'Be concise']

puts translation.text
```

Up to 10 custom instructions can be specified, each with a maximum of 300 characters.
The target language must be `de`, `en`, `es`, `fr`, `it`, `ja`, `ko`, `zh` or any variants.
Note that using `custom_instructions` will automatically use `quality_optimized` models,
and cannot be combined with `model_type: 'latency_optimized'`.

The following parameters will be automatically converted:

| Parameter             | Conversion
| --------------------- | ---------------
| `preserve_formatting` | Converts `false` to `'0'` and `true` to `'1'`
| `split_sentences`     | Converts `false` to `'0'` and `true` to `'1'`
| `outline_detection`   | Converts `false` to `'0'` and `true` to `'1'`
| `splitting_tags`      | Converts arrays to strings joining by commas
| `non_splitting_tags`  | Converts arrays to strings joining by commas
| `ignore_tags`         | Converts arrays to strings joining by commas
| `formality`           | No conversion applied
| `glossary_id`         | No conversion applied
| `style_rule`          | No conversion applied (can be a string ID or a StyleRule object)
| `translation_memory`  | No conversion applied (can be a string ID or a TranslationMemory object)
| `translation_memory_threshold` | No conversion applied (integer 0-100, recommended minimum 75)
| `context`             | No conversion applied
| `custom_instructions` | No conversion applied
| `tag_handling_version` | No conversion applied
| `extra_body_parameters` | Hash of extra parameters to pass in the body of the HTTP request. Can be used to access beta features, or to override built-in parameters for testing purposes. Extra parameters can override keys explicitly set by the client.

### Rephrase Text

To rephrase or improve text, including changing the writing style or tone of the text, use the `rephrase` method:

```rb
rephrased_text = DeepL.rephrase 'you will acquire new rephrased text', 'EN'

puts rephrased_text.class
# => DeepL::Resources::Text
puts rephrased_text.text
# => 'You get new rephrased text.'
```

As with translate, the text input can be a single string or an array of strings.

You can use the additional arguments to specify the writing style or tone you want for the rephrased text:

```rb
rephrased_text = DeepL.rephrase 'you will acquire new rephrased text', 'EN', 'casual'

puts rephrased_text.text
# => 'You'll get new, rephrased text.'
```

```rb
rephrased_text = DeepL.rephrase 'you will acquire new rephrased text', 'EN', nil, 'friendly'

puts rephrased_text.text
# => 'You'll get to enjoy new, rephrased text!'
```

### Glossaries

To create a glossary, use the `glossaries.create` method. The glossary `entries` argument should be an array of text pairs. Each pair includes the source and the target translations.

```rb
entries = [
  ['Hello World', 'Hola Tierra'],
  ['car', 'auto']
]
glossary = DeepL.glossaries.create 'Mi Glosario', 'EN', 'ES', entries

puts glossary.class
# => DeepL::Resources::Glossary
puts glossary.id
# => 'aa48c7f0-0d02-413e-8a06-d5bbf0ca7a6e'
puts glossary.entry_count
# => 2
```

Created glossaries can be used in the `translate` method by specifying the `glossary_id` option:

```rb
translation = DeepL.translate 'Hello World', 'EN', 'ES', glossary_id: 'aa48c7f0-0d02-413e-8a06-d5bbf0ca7a6e'

puts translation.class
# => DeepL::Resources::Text
puts translation.text
# => 'Hola Tierra'

translation = DeepL.translate "I wish we had a car.", 'EN', 'ES', glossary_id: 'aa48c7f0-0d02-413e-8a06-d5bbf0ca7a6e'

puts translation.class
# => DeepL::Resources::Text
puts translation.text
# => Ojalá tuviéramos un auto.
```

To use more than one glossary at once, specify the `glossary_ids` option with an
array of up to 5 glossary IDs (as strings or `DeepL::Resources::Glossary`
objects) instead of `glossary_id`. This works for both text and document
translation. `glossary_ids` requires `source_lang` to be set, cannot be combined
with `glossary_id`, and raises `ArgumentError` if these rules are violated or
more than 5 IDs are provided:

```rb
# Text translation with multiple glossaries
translation = DeepL.translate 'Hello World', 'EN', 'ES',
                              glossary_ids: ['aa48c7f0-0d02-413e-8a06-d5bbf0ca7a6e',
                                             'bb59d8g1-1e13-524f-9b17-e6ccg1db8b7f']

# Document translation with multiple glossaries
handle = DeepL.document.upload 'my_document.docx', 'EN', 'ES', 'my_document.docx',
                              glossary_ids: ['aa48c7f0-0d02-413e-8a06-d5bbf0ca7a6e',
                                             'bb59d8g1-1e13-524f-9b17-e6ccg1db8b7f']
```

To list all the glossaries available, use the `glossaries.list` method:

```rb
glossaries = DeepL.glossaries.list

puts glossaries.class
# => Array
puts glossaries.first.class
# => DeepL::Resources::Glossary
```

To find an existing glossary, use the `glossaries.find` method:

```rb
glossary = DeepL.glossaries.find 'aa48c7f0-0d02-413e-8a06-d5bbf0ca7a6e'

puts glossary.class
# => DeepL::Resources::Glossary
```

The glossary resource does not include the glossary entries. To list the glossary entries, use the `glossaries.entries` method:

```rb
entries = DeepL.glossaries.entries 'aa48c7f0-0d02-413e-8a06-d5bbf0ca7a6e'

puts entries.class
# => Array
puts entries.size
# => 2
pp entries.first
# => ["Hello World", "Hola Tierra"]
```

To delete an existing glossary, use the `glossaries.destroy` method:

```rb
glossary_id = DeepL.glossaries.destroy 'aa48c7f0-0d02-413e-8a06-d5bbf0ca7a6e'

puts glossary_id
# => aa48c7f0-0d02-413e-8a06-d5bbf0ca7a6e
```

You can list all the language pairs supported by glossaries using the `glossaries.language_pairs` method:

```rb
language_pairs = DeepL.glossaries.language_pairs

puts language_pairs.class
# => Array
puts language_pairs.first.class
# => DeepL::Resources::LanguagePair
puts language_pairs.first.source_lang
# => en
puts language_pairs.first.target_lang
# => de
```

### Style Rules

Style rules allow you to customize your translations using a managed, shared list
of rules for style, formatting, and more. Multiple style rules can be stored with
your account, each with a user-specified name and a uniquely-assigned ID.

#### Creating a style rule

Use `create` to create a new style rule with a name and language code. You can
optionally provide `configured_rules` and `custom_instructions`.

```rb
# Simple creation with just a name and language
style_rule = DeepL.style_rules.create('My Style Rule', 'en')
puts "Created: #{style_rule.name} (#{style_rule.style_id})"

# Creation with configured rules and custom instructions
style_rule = DeepL.style_rules.create(
  'Formal English',
  'en',
  configured_rules: { style_and_tone: { formality: 'formal' } },
  custom_instructions: [{ label: 'Tone', prompt: 'Always use formal language' }]
)
```

#### Retrieving and listing style rules

Use `find` to retrieve a single style rule by ID, or `list` to list all style
rules.

`list` returns a list of `StyleRule` objects corresponding to all of your stored
style rules. The method accepts optional parameters: `page` (page number for
pagination, 0-indexed), `page_size` (number of items per page), and `detailed`.
When `true`, the response includes `configured_rules` and `custom_instructions`
for each style rule. When `false` (default), these fields are omitted for faster
responses.

```rb
# Get a single style rule by ID
style_rule = DeepL.style_rules.find('YOUR_STYLE_ID')
puts "#{style_rule.name} (#{style_rule.language})"

# List all style rules
style_rules = DeepL.style_rules.list
style_rules.each do |rule|
  puts "#{rule.name} (#{rule.style_id})"
end

# List with pagination
style_rules = DeepL.style_rules.list(page: 0, page_size: 10)

# List with detailed configuration
style_rules = DeepL.style_rules.list(detailed: true)
style_rules.each do |rule|
  if rule.configured_rules
    puts "  Number formatting: #{rule.configured_rules.numbers.keys.join(', ')}"
  end
end
```

#### Updating a style rule

Use `update_name` to rename a style rule, and `update_configured_rules` to
update its configured rules.

```rb
# Update the name
updated = DeepL.style_rules.update_name('YOUR_STYLE_ID', 'New Name')

# Update configured rules
updated = DeepL.style_rules.update_configured_rules(
  'YOUR_STYLE_ID',
  { style_and_tone: { formality: 'formal' } }
)
```

The `configured_rules` hash supports the following categories: `dates_and_times`,
`formatting`, `numbers`, `punctuation`, `spelling_and_grammar`, `style_and_tone`,
and `vocabulary`.

#### Managing custom instructions

Custom instructions allow you to add free-text prompts to a style rule. Each
instruction has an `id`, `label`, `prompt`, and `source_language`. Use
`create_custom_instruction`, `find_custom_instruction`,
`update_custom_instruction`, and `destroy_custom_instruction` to manage them.

```rb
# Create a custom instruction
instruction = DeepL.style_rules.create_custom_instruction(
  'YOUR_STYLE_ID', 'Formal tone', 'Always use formal language'
)
puts "Created instruction: #{instruction.id}"

# Create with an optional source language
instruction = DeepL.style_rules.create_custom_instruction(
  'YOUR_STYLE_ID', 'Formal tone', 'Always use formal language', 'en'
)

# Get a custom instruction
instruction = DeepL.style_rules.find_custom_instruction('YOUR_STYLE_ID', instruction.id)

# Update a custom instruction
updated = DeepL.style_rules.update_custom_instruction(
  'YOUR_STYLE_ID', instruction.id, 'Updated label', 'Use very formal language'
)

# Delete a custom instruction
DeepL.style_rules.destroy_custom_instruction('YOUR_STYLE_ID', instruction.id)
```

#### Deleting a style rule

Use `destroy` to delete a style rule by ID.

```rb
DeepL.style_rules.destroy('YOUR_STYLE_ID')
```

#### Using style rules in translations

Style rules can be used in the `translate` method by specifying the `style_rule` option
with either a style rule ID string or a `StyleRule` object:

```rb
# Using a style rule ID
translation = DeepL.translate 'Hello World', 'EN', 'ES', style_rule: 'dca2e053-8ae5-45e6-a0d2-881156e7f4e4'

# Or using a StyleRule object
style_rules = DeepL.style_rules.list
translation = DeepL.translate 'Hello World', 'EN', 'ES', style_rule: style_rules.first
```

The same `style_rule` option can be passed to document translation via
`DeepL.document.upload` (or `DeepL.document.translate_document`), accepting either
a style rule ID string or a `StyleRule` object:

```rb
handle = DeepL.document.upload 'my_document.docx', 'EN', 'ES', 'my_document.docx',
                              style_rule: 'dca2e053-8ae5-45e6-a0d2-881156e7f4e4'
```

### Translation Memories

Translation memories allow you to store and reuse previously created translations.
They can be used in text translation requests to improve consistency by matching
against stored segments. Multiple translation memories can be stored with your
account, each with a source language and one or more target languages.

Translation memories can also be managed in the DeepL UI via
https://www.deepl.com/translation-memory.

Every method that takes a translation memory accepts either a string containing
the translation memory ID or a `TranslationMemory` object.

#### Listing translation memories

`translation_memories.list` returns a list of `TranslationMemory` objects
for your stored translation memories. The method accepts optional parameters:
`page` (page number for pagination, 0-indexed) and `page_size` (number of items
per page, max 25).

```rb
# List translation memories
translation_memories = DeepL.translation_memories.list
translation_memories.each do |tm|
  puts "#{tm.name} (#{tm.translation_memory_id})"
  puts "  Source: #{tm.source_language}, Targets: #{tm.target_languages.join(', ')}"
  puts "  Segments: #{tm.segment_count}"
end

# List with pagination
translation_memories = DeepL.translation_memories.list(page: 0, page_size: 10)
```

#### Retrieving a single translation memory

`translation_memories.find` retrieves one translation memory by ID. In addition
to the fields returned by `list`, the resource carries the `creation_time` and
`updated_time` timestamps.

```rb
tm = DeepL.translation_memories.find 'YOUR_TM_ID'

puts tm.class
# => DeepL::Resources::TranslationMemory
puts tm.name
# => 'Legal'
puts tm.segment_count
# => 12
puts tm.creation_time.class
# => Time
```

#### Listing the segments of a translation memory

`translation_memories.segments` returns one page of the segments of a
translation memory as a `TranslationMemorySegments` object. Each segment holds
the source text and one target per target language of the translation memory.

Pagination is cursor-based: omit `page_cursor` on the first call, then pass the
`next_page_cursor` of the previous response until `next_page?` is `false`. The
method also accepts `page_size` (1-100, defaults to 50), `filter_text` (a
substring matched against the source and target texts, at least 2 characters)
and `filter_case_sensitive` (defaults to `false`).

Note that `segment_count` is the number of segments stored in the translation
memory; a text filter does not reduce it.

```rb
page = DeepL.translation_memories.segments 'YOUR_TM_ID', page_size: 50

puts page.class
# => DeepL::Resources::TranslationMemorySegments
puts page.segment_count
# => 12
puts page.segments.first.source_text
# => 'Quelltext Nummer 0'
puts page.segments.first.targets.first.target_text
# => 'Source text number 0'

# Walk through every page of segments
while page.next_page?
  page = DeepL.translation_memories.segments 'YOUR_TM_ID',
                                             page_size: 50,
                                             page_cursor: page.next_page_cursor
end

# Only the segments matching a text
page = DeepL.translation_memories.segments 'YOUR_TM_ID',
                                           filter_text: 'Nummer 1',
                                           filter_case_sensitive: true
```

#### Importing a translation memory

`translation_memories.import_from_filepath` creates a new translation memory
from a TMX file. It creates the import job, uploads the file and waits for the
processing to finish, and returns the finished `TranslationMemoryJob`. Its
result carries the ID of the newly created translation memory.

```rb
job = DeepL.translation_memories.import_from_filepath 'legal.tmx',
                                                      display_name: 'Legal',
                                                      timeout_s: 300

puts job.class
# => DeepL::Resources::TranslationMemoryJob
puts job.status
# => 'completed'
puts job.result.translation_memory_id
# => 'a74d88fb-ed2a-4943-a664-a4512398b994'
puts job.result.skipped_segment_count
# => 0
```

The three steps can also be performed separately, for example to upload a file
that is not available on the local file system. The upload URL is a pre-signed
storage URL outside of the DeepL API, so no authorization header is sent with
the upload.

```rb
content = File.binread 'legal.tmx'
created = DeepL.translation_memories.create_import 'legal.tmx', content.bytesize,
                                                   content_type: 'application/xml',
                                                   display_name: 'Legal'

puts created.upload_url
# => 'https://...'

DeepL.translation_memories.upload_file created, content
job = DeepL.translation_memories.wait_until_job_done created.job_id
```

Until the file is uploaded the job stays in the `awaiting_input` status and
`result.required_action` describes what is missing. The API detects the upload
asynchronously, so the job keeps reporting `awaiting_input` for a while
afterwards, typically around half a minute, before it completes.
`wait_until_job_done` therefore polls through that status like any other
non-terminal one. A job whose file is never uploaded does not finish on its own,
so pass `timeout_s` when that is a possibility.

#### Exporting a translation memory

`translation_memories.export_to_filepath` writes a translation memory to a TMX
file. It creates the export job, waits for it to finish and downloads the
result, overwriting the output file if it already exists.

```rb
job = DeepL.translation_memories.export_to_filepath 'YOUR_TM_ID', 'export.tmx'

puts job.status
# => 'completed'
```

The steps can be performed separately as well. Repeating the export of an
unchanged translation memory reuses the previously completed job instead of
starting a new one, which `reused_existing?` reports. Just like the upload URL,
the download URL is a pre-signed storage URL and is requested without an
authorization header.

```rb
created = DeepL.translation_memories.create_export 'YOUR_TM_ID'

puts created.reused_existing?
# => false

job = DeepL.translation_memories.wait_until_job_done created.job_id

puts job.result.download_url
# => 'https://...'

DeepL.translation_memories.download_export job, 'export.tmx'
```

#### Tracking import and export jobs

`translation_memories.find_job` returns the current status of an import or
export job, and `translation_memories.wait_until_job_done` polls it every five
seconds until it finished, raising if the job failed or expired. Pass
`timeout_s` to give up after a number of seconds instead of waiting forever.

```rb
job = DeepL.translation_memories.find_job 'YOUR_JOB_ID'

puts job.operation
# => 'import'
puts job.status
# => 'processing'
puts job.finished?
# => false
```

The status is one of `awaiting_input`, `processing`, `completed`, `downloaded`,
`failed` or `expired`.

#### Deleting a translation memory

`translation_memories.destroy` deletes a translation memory and returns its ID.

```rb
DeepL.translation_memories.destroy 'YOUR_TM_ID'
# => 'YOUR_TM_ID'
```

#### Using a translation memory in translations

Pass the `translation_memory` parameter to `translate` to use a translation
memory. You can pass either a string containing the translation memory ID, or a
`TranslationMemory` object. Use `translation_memory_threshold` to control the
minimum matching percentage for fuzzy matches (0-100, recommended minimum of
75%).

```rb
# Using a translation memory ID
translation = DeepL.translate 'Hello, world!', 'EN', 'DE',
                              translation_memory: 'YOUR_TM_ID',
                              translation_memory_threshold: 80

# Or using a TranslationMemory object
translation_memories = DeepL.translation_memories.list
translation = DeepL.translate 'Hello, world!', 'EN', 'DE',
                              translation_memory: translation_memories.first
```

The same `translation_memory` and `translation_memory_threshold` options can be
passed to document translation via `DeepL.document.upload` (or
`DeepL.document.translate_document`). The `translation_memory` option accepts
either a translation memory ID string or a `TranslationMemory` object:

```rb
handle = DeepL.document.upload 'my_document.docx', 'EN', 'DE', 'my_document.docx',
                              translation_memory: 'YOUR_TM_ID',
                              translation_memory_threshold: 80
```

### Monitor usage

To check current API usage, use:

```rb
usage = DeepL.usage

puts usage.character_count
# => 180118
puts usage.character_limit
# => 1250000
```

### Translate documents

To translate a document, use the `document.translate_document` method. Example:

```rb
DeepL.document.translate_document('/path/to/spanish_document.pdf', '/path/to/translated_document.pdf', 'ES', 'EN')
```

The lower level `upload`, `get_status` and `download` methods are also exposed, as well as the convenience method `wait_until_document_translation_finished` on the `DocumentHandle` object, which would replace `get_status`:
```rb
doc_handle = DeepL.document.upload('/path/to/spanish_document.pdf', 'ES', 'EN')
doc_status = doc_handle.wait_until_document_translation_finished # alternatively poll `DeepL.document.get_status`
# until the `doc_status.successful?`
DeepL.document.download(doc_handle, '/path/to/translated_document.pdf') unless doc_status.error?
```

You can also pass additional options to document translation methods, including `extra_body_parameters`:

```rb
options = {
  formality: 'more',
  extra_body_parameters: { example_param: 'true' }
}
doc_handle = DeepL.document.upload('/path/to/spanish_document.pdf', 'ES', 'EN', nil, options)
```

The `extra_body_parameters` option allows you to pass arbitrary parameters in the request body. This can be used to access beta features by adding new parameters, or to override built-in parameters (such as `target_lang`, `source_lang`, etc.) for testing purposes.

### Sending additional HTTP headers

You can pass additional HTTP headers to `translate`, `rephrase`, and the
`document` methods. For example, to send the `X-DeepL-Reporting-Tag` header
for usage reporting (see the [cookbook entry](https://developers.deepl.com/docs/learning-how-tos/cookbook/sending-custom-reporting-tags-from-client-libraries)):

```rb
additional_headers = { 'X-DeepL-Reporting-Tag' => 'my-tag' }
translation = DeepL.translate 'Hello, world!', 'EN', 'DE', {}, additional_headers
rephrased = DeepL.rephrase 'Hello, world!', 'EN', nil, nil, {}, additional_headers
```

### Handle exceptions

You can capture and process exceptions that may be raised during API calls. These are all the possible exceptions:

| Exception class | Description |
| --------------- | ----------- |
| `DeepL::Exceptions::AuthorizationFailed` | The authorization process has failed. Check your `auth_key` value. |
| `DeepL::Exceptions::BadRequest` | Something is wrong in your request. Check `exception.message` for more information. |
| `DeepL::Exceptions::DocumentTranslationError` | An error occured during document translation. Check `exception.message` for more information. |
| `DeepL::Exceptions::LimitExceeded` | You've reached the API's call limit. |
| `DeepL::Exceptions::QuotaExceeded` | You've reached the API's character limit. |
| `DeepL::Exceptions::RequestError` | An unkown request error. Check `exception.response` and `exception.request` for more information. |
| `DeepL::Exceptions::NotSupported` | The requested method or API endpoint is not supported. |
| `DeepL::Exceptions::RequestEntityTooLarge` | Your request is too large, reduce the amount of data you are sending. The API has a request size limit of 128 KiB. |
| `DeepL::Exceptions::ServerError` | An error occured in the DeepL API, wait a short amount of time and retry. |

An exampling of handling a generic exception:

```rb
def my_method
  item = DeepL.translate 'This is my text', nil, 'ES'
rescue DeepL::Exceptions::RequestError => e
  puts 'Oops!'
  puts "Code: #{e.response.code}"
  puts "Response body: #{e.response.body}"
  puts "Request body: #{e.request.body}"
end
```

### Logging

To enable logging, pass a suitable logging object (e.g. the default `Logger` from the Ruby standard library) when configuring the library. The library logs HTTP requests to `INFO` and debug information to `DEBUG`. Example:

```rb
require 'logger'

logger = Logger.new(STDOUT)
logger.level = Logger::INFO

deepl.configure do |config|
  config.auth_key = configuration.auth_key
  config.logger = logger
end
```

### Proxy configuration

To use HTTP proxies, a session needs to be used. The proxy can then be configured as part of the HTTP client options:

```rb
client_options = HTTPClientOptions.new({ 'proxy_addr' => 'http://localhost', 'proxy_port' => 80 })
deepl.with_session(client_options) do |session|
  # ...
end
```

### Anonymous platform information

By default, we send some basic information about the platform the client library is running on with each request, see [here for an explanation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/User-Agent). This data is completely anonymous and only used to improve our product, not track any individual users. If you do not wish to send this data, you can opt-out by setting the `send_platform_info` flag in the configuration to `false` like so:

```rb
deepl.configure({}, nil, nil, false) do |config|
  # ...
end
```

You can also complete customize the `User-Agent` header like so:

```rb
deepl.configure do |config|
  config.user_agent = 'myCustomUserAgent'
end
```

### Sending multiple requests

When writing an application that send multiple requests, using a HTTP session will give better performance through [HTTP Keep-Alive](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Keep-Alive). You can use it by simply wrapping your requests in a `with_session` block:

```rb
deepl.with_session do |session|
  deepl.translate(sentence1, 'DE', 'EN-GB')
  deepl.translate(sentence2, 'DE', 'EN-GB')
  deepl.translate(sentence3, 'DE', 'EN-GB')
end
```

### Writing a plugin

If you use this library in an application, please identify the application by setting the name and version of the plugin:

```rb
deepl.configure({}, 'MyTranslationPlugin', '1.0.1') do |config|
  # ...
end
```

This information is passed along when the library makes calls to the DeepL API. Both name and version are required. Please note that setting the `User-Agent` header via `deepl.configure` will override this setting, if you need to use this, please manually identify your Application in the `User-Agent` header.

## Options Constants

The available values for various possible options are provided under the `DeepL::Constants` namespace. The currently available options are

`TagHandling`
`SplitSentences`
`ModelType`
`Formality`
`WritingStyle`
`Tone`

To view all the possible options for a given constant, call `options`:

```rb
all_available_tones = DeepL::Constants::Tones.options
```

To check if a given string is a possible option for a given constant, call `valid?`:

```rb
DeepL::Constants::Tones.valid?('friendly') # true
DeepL::Constants::Tones.valid?('rude') # false
```

## Integrations

### Ruby on Rails

You may use this gem as a standalone service by creating an initializer on your
`config/initializers` folder with your DeepL configuration. For example:

```rb
# config/initializers/deepl.rb
DeepL.configure do |config|
  # Your configuration goes here
end
```

Since the DeepL service is defined globally, you can use service anywhere in your code
(controllers, models, views, jobs, plain ruby objects… you name it).

### i18n-tasks

You may also take a look at [`i18n-tasks`](https://github.com/glebm/i18n-tasks), which is a gem
that helps you find and manage missing and unused translations. `deepl-rb` is used as one of the
backend services to translate content.

## Development

Clone the repository, and install its dependencies:

```sh
git clone https://github.com/DeepLcom/deepl-rb
cd deepl-rb
bundle install
```

To run tests (rspec and rubocop), use

```
bundle exec rake test
```

## Acknowledgements

This library was originally developed by [Daniel Herzog](mailto:info@danielherzog.es), we are grateful for his contributions. Beginning with v3.0.0, DeepL took over development and officially supports and maintains the library together with Daniel.