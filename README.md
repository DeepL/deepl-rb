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

### Creating a client

Create a `DeepL::Client` with your authentication key. Each client owns its configuration and
HTTP connection, so several clients with different keys or options can be used side by side.
The client reads no environment variables:

```rb
client = DeepL::Client.new(ENV.fetch('DEEPL_AUTH_KEY'))
```

`DeepL::Client.new` accepts these keyword arguments:

| Option | Default | Description |
| ------ | ------- | ----------- |
| `server_url:` | `https://api-free.deepl.com` for Free keys (ending in `:fx`), else `https://api.deepl.com` | Base URL of the DeepL API. A path prefix is kept. |
| `headers:` | `{}` | HTTP headers sent with every DeepL API request (not to pre-signed storage URLs). A `User-Agent` replaces the library's; `Authorization` cannot be replaced. |
| `max_retries:` | `5` | Retries after the first attempt, for HTTP 429, any 5xx and network failures. |
| `timeout:` | `10` | Timeout of each attempt in seconds. A longer backoff interval takes precedence. |
| `proxy:` | none | Proxy URL, e.g. `http://user:password@proxy.example:8080`. |
| `send_platform_info:` | `true` | Adds the OS and Ruby versions to the `User-Agent`. |
| `app_info:` | none | A `DeepL::AppInfo` or a hash with `app_name` and `app_version`, added to the `User-Agent`. |
| `http_client_options:` | none | A `DeepL::HTTPClientOptions` with proxy, certificate, SSL verification and per-phase timeouts. Its timeouts take precedence over `timeout:`. |
| `logger:` | none | Logger for requests and retries, see [Logging](#logging). |

The authentication key is trimmed; an empty key raises `ArgumentError`.
`DeepL::Client.free_account_auth_key?(key)` returns whether a key is a DeepL API Free key.

`DeepL::Client` offers text translation (`translate_text`, see [Translate](#translate)),
document translation (`translate_document` and its steps, see
[Translate documents](#translate-documents)), rephrasing and correction (`rephrase_text` and
`correct_text`, see [Rephrase Text](#rephrase-text) and [Correct Text](#correct-text)) and
spoken terms (see
[Spoken terms](#spoken-terms)); for the other operations, use the module-level API shown in the following sections. The module-level API (`DeepL.configure`, `DeepL.translate`, `DeepL.glossaries`, ...)
is deprecated: each method prints a deprecation warning once per process, and it will be
removed in the next major version.

### Module-level configuration (deprecated)

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
end
```

Without a host, keys ending in `:fx` use `https://api-free.deepl.com`. The `version` setting
is deprecated.

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

`DeepL::Resources::Language#supports_formality?` is `true` or `false` for target languages and
`nil` for source languages.

#### Languages per resource

`DeepL.languages_for_resource` returns the languages supported by a given API resource
(`translate_text`, `translate_document`, `glossary`, `voice`, `write`, `style_rules` or
`translation_memory`), with source/target usability and per-feature support. Pass
`include: ['beta']` and/or `'external'` to also list beta languages and features or features that
rely on third-party providers:

```rb
languages = DeepL.languages_for_resource('translate_text', include: ['beta'])

german = languages.find { |language| language.code == 'de' }
puts german.usable_as_target?
# => true
puts german.supports?(:formality)
# => true
puts german.features['formality'].status
# => "stable"
```

`DeepL.language_resources` lists every resource with its features, and whether a feature must be
supported by the source language, the target language, or both:

```rb
translate_text = DeepL.language_resources.find { |resource| resource.resource == 'translate_text' }
formality = translate_text.features['formality']
puts formality.needs_source_support?
# => false
puts formality.needs_target_support?
# => true
```

### Translate

To translate a simple text, use the `translate_text` method of `DeepL::Client`:

```rb
translation = client.translate_text 'This is my text', 'EN', 'ES'

puts translation.class
# => DeepL::Resources::Text
puts translation.text
# => 'Este es mi texto'
puts translation.billed_characters
# => 15
```

Each result has `text`, `detected_source_language`, `billed_characters` (the characters
billed for the text; the library always asks the API for it), `model_type_used` and
`tag_handling_version` (the tag handling version the API used, when tag handling was
requested). A field the response does not contain is `nil`.

Enable auto-detect source language by skipping the source language with `nil`:

```rb
translation = client.translate_text 'This is my text', nil, 'ES'

puts translation.detected_source_language
# => 'EN'
```

Translate a list of texts by passing an array as an argument. An array, also one with a
single text, returns an array of results:

```rb
texts = ['Sample text', 'Another text']
translations = client.translate_text texts, 'EN', 'ES'

puts translations.class
# => Array
puts translations.first.class
# => DeepL::Resources::Text
```

Options are passed as keyword arguments; an option set to `nil` is not sent. You can use
options like `tag_handling`, `split_sentences`, `non_splitting_tags` or `ignore_tags`:

```rb
translation = client.translate_text '<p>A sample</p>', 'EN', 'ES',
                                    tag_handling: 'xml', split_sentences: false,
                                    non_splitting_tags: 'h1', ignore_tags: %w[code pre]

puts translation.text
# => "<p>Una muestra</p>"
```

To specify which version of the tag handling algorithm to use, you can use the `tag_handling_version` parameter:

```rb
translation = client.translate_text '<p>A sample</p>', 'EN', 'ES',
                                    tag_handling: 'xml',
                                    tag_handling_version: DeepL::Constants::TagHandlingVersion::V2

puts translation.text
# => "<p>Una muestra</p>"
puts translation.tag_handling_version
# => "v2"
```

The available values are `'v1'` and `'v2'` (`DeepL::Constants::TagHandlingVersion::V1` and
`V2`); other strings are sent as given.

To translate with context, simply supply the `context` parameter:

```rb
translation = client.translate_text 'That is hot!', 'EN', 'ES',
                                    context: 'He did not like the jalapenos in his meal.'

puts translation.text
# => "¡Eso es picante!"
```

To specify a type of translation model to use, you can use the `model_type` option:

```rb
translation = client.translate_text 'That is hot!', 'EN', 'DE',
                                    model_type: 'quality_optimized'
```

This would use next-gen translation models for the translation. The available values are

- `'quality_optimized'`: use a translation model that maximizes translation quality, at the
  cost of response time. This option may be unavailable for some language pairs.
- `'prefer_quality_optimized'`: use the highest-quality translation model for the given
  language pair.
- `'latency_optimized'`: use a translation model that minimizes response time, at the cost
  of translation quality.

To translate with custom instructions, supply the `custom_instructions` parameter, an array
of instructions. A single string is sent as one instruction, commas included:

```rb
translation = client.translate_text 'Hello, world!', 'EN', 'DE',
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
| `glossary`            | A glossary ID string, a `Glossary` or a `MultilingualGlossary` object, sent as `glossary_id` (see [Glossaries](#glossaries))
| `glossary_id`         | Deprecated, use `glossary`. No conversion applied
| `style_rule`          | No conversion applied (can be a string ID or a StyleRule object)
| `style_profile`       | No conversion applied (can be a string ID or a StyleProfile object, see [Style profiles](#style-profiles))
| `translation_memory`  | No conversion applied (can be a string ID or a TranslationMemory object)
| `translation_memory_threshold` | No conversion applied (integer 0-100, recommended minimum 75)
| `context`             | No conversion applied
| `custom_instructions` | An array of strings; a string is sent as a one-element array
| `tag_handling_version` | No conversion applied (`DeepL::Constants::TagHandlingVersion`)
| `extra_body_parameters` | Hash of extra parameters to pass in the body of the HTTP request. Can be used to access beta features, or to override built-in parameters for testing purposes. Extra parameters can override keys explicitly set by the client.

`show_billed_characters: true` is always sent.

The deprecated module-level `DeepL.translate(text, source_lang, target_lang, options = {},
additional_headers = {})` takes the same options. Unlike `translate_text`, it returns a single
result for a one-element array.

### Rephrase Text

To rephrase or improve text, including changing the writing style or tone of the text, use
the `rephrase_text` method of `DeepL::Client`:

```rb
rephrased_text = client.rephrase_text 'you will acquire new rephrased text', 'EN'

puts rephrased_text.class
# => DeepL::Resources::Text
puts rephrased_text.text
# => 'You get new rephrased text.'
puts rephrased_text.detected_source_language
# => 'en'
puts rephrased_text.target_language
# => 'en-US'
```

As with `translate_text`, the text can be a string or an array of strings: a string returns a
`DeepL::Resources::Text`, an array returns an array of them (also for an array with one
element). The target language is optional.

Use the `writing_style:` or `tone:` keyword to choose the writing style or tone of the
rephrased text (`DeepL::Constants::WritingStyle` and `DeepL::Constants::Tone` list the values;
any string is sent as given). `extra_body_parameters:` is a hash added to the request body
last; it replaces fields of the same name.

```rb
rephrased_text = client.rephrase_text 'you will acquire new rephrased text', 'EN',
                                      writing_style: 'casual'

puts rephrased_text.text
# => 'You'll get new, rephrased text.'
```

```rb
rephrased_text = client.rephrase_text 'you will acquire new rephrased text', 'EN',
                                      tone: DeepL::Constants::Tone::FRIENDLY

puts rephrased_text.text
# => 'You'll get to enjoy new, rephrased text!'
```

The deprecated module-level `DeepL.rephrase(text, target_lang = nil, writing_style = nil,
tone = nil, options = {}, additional_headers = {})` takes the writing style and tone as
positional arguments. Unlike `rephrase_text`, it returns a single result for a one-element
array.

### Correct Text

To fix grammar, spelling and punctuation, use the `correct_text` method of `DeepL::Client`.
It accepts a string or an array of strings, plus an optional target language and
`extra_body_parameters:`:

```ruby
corrected = client.correct_text 'I has a apple.', 'en-US'
puts corrected.text
# => 'It has an apple.'
puts corrected.target_language
# => 'en-US'
```

A string returns a `DeepL::Resources::Text`; an array returns an array of them (also for an
array with one element). Empty text raises `ArgumentError`. The deprecated module-level
`DeepL.correct(text, target_lang = nil, options = {}, additional_headers = {})` behaves the
same.

Both methods raise `DeepL::Exceptions::Error` if the response contains fewer improvements than
texts were sent.

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

Created glossaries can be used in text and document translation by specifying the
`glossary` option, a glossary ID or a `Glossary` / `MultilingualGlossary` object. It is sent
as `glossary_id` and replaces the deprecated `glossary_id` option:

```rb
translation = client.translate_text 'Hello World', 'EN', 'ES', glossary: 'aa48c7f0-0d02-413e-8a06-d5bbf0ca7a6e'

puts translation.class
# => DeepL::Resources::Text
puts translation.text
# => 'Hola Tierra'

translation = client.translate_text "I wish we had a car.", 'EN', 'ES', glossary: glossary

puts translation.class
# => DeepL::Resources::Text
puts translation.text
# => Ojalá tuviéramos un auto.
```

To use more than one glossary at once, specify the `glossary_ids` option with an
array of up to 5 glossary IDs (as strings or `DeepL::Resources::Glossary`
objects) instead of `glossary`. This works for both text and document
translation. `glossary_ids` requires `source_lang` to be set, cannot be combined
with `glossary` or `glossary_id`, and raises `ArgumentError` if these rules are violated or
more than 5 IDs are provided:

```rb
# Text translation with multiple glossaries
translation = client.translate_text 'Hello World', 'EN', 'ES',
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

### Multilingual glossaries

Multilingual glossaries (v3) let you group multiple language-pair dictionaries
under a single glossary. They are accessed through
`DeepL.multilingual_glossaries`.

To create a multilingual glossary, pass a name and an array of dictionaries.
Each dictionary contains its source language, target language, and entries
(either as an array of source/target pairs or as a TSV string):

```rb
dictionaries = [
  {
    source_lang: 'EN',
    target_lang: 'DE',
    entries: [['Hello', 'Hallo'], ['World', 'Welt']]
  },
  {
    source_lang: 'EN',
    target_lang: 'FR',
    entries: [['Hello', 'Bonjour']]
  }
]
glossary = DeepL.multilingual_glossaries.create 'My Glossary', dictionaries

puts glossary.class
# => DeepL::Resources::MultilingualGlossary
puts glossary.id
# => 'aa48c7f0-0d02-413e-8a06-d5bbf0ca7a6e'
puts glossary.dictionaries.first.entry_count
# => 2
```

To create a multilingual glossary from CSV content, use `create_with_csv`:

```rb
csv_content = File.read('entries.csv')
glossary = DeepL.multilingual_glossaries.create_with_csv(
  'My Glossary', 'EN', 'DE', csv_content
)
```

List or fetch multilingual glossaries with `list` and `find`:

```rb
glossaries = DeepL.multilingual_glossaries.list
glossary = DeepL.multilingual_glossaries.find 'aa48c7f0-0d02-413e-8a06-d5bbf0ca7a6e'
```

To fetch the entries for a specific language pair, use `entries`:

```rb
dictionaries = DeepL.multilingual_glossaries.entries(
  'aa48c7f0-0d02-413e-8a06-d5bbf0ca7a6e', 'EN', 'DE'
)
puts dictionaries.first.entries
# => "Hello\tHallo\nWorld\tWelt\n"
```

To update the glossary name, use `update_name`. To update or add a dictionary
for a language pair, use `update_dictionary` (or
`update_dictionary_with_csv`). To replace the entries of an existing dictionary,
use `replace_dictionary` (or `replace_dictionary_with_csv`):

```rb
DeepL.multilingual_glossaries.update_name(glossary.id, 'Renamed Glossary')
DeepL.multilingual_glossaries.update_dictionary(
  glossary.id, 'EN', 'FR', [['Hello', 'Bonjour'], ['World', 'Monde']]
)
DeepL.multilingual_glossaries.replace_dictionary(
  glossary.id, 'EN', 'DE', [['Hello', 'Hallo'], ['car', 'Auto']]
)
```

To delete an entire multilingual glossary or just one of its dictionaries:

```rb
DeepL.multilingual_glossaries.destroy_dictionary(glossary.id, 'EN', 'FR')
DeepL.multilingual_glossaries.destroy(glossary.id)
```

### Spoken terms

Spoken terms collections improve the transcription of terms such as product
names. A collection holds one list of terms per language and is managed through
`DeepL::Client`. Every method that takes a collection accepts its ID or a
`DeepL::Resources::SpokenTerms` object. Terms are passed and returned as arrays
of strings.

To create a collection, pass a name and one `DeepL::Resources::SpokenTermsEntries`
(or a hash with `:lang` and `:entries`) per language. Terms are checked like
glossary terms: each term is stripped of surrounding whitespace and sent stripped,
and `create_spoken_terms`, `update_spoken_terms` and `replace_spoken_terms_list`
raise `ArgumentError` before sending anything if a term is then empty or contains
a C0 or C1 control character (such as a tab or newline), U+2028 or U+2029.
Further options, such as `extra_body_parameters`, are given as additional
keywords:

```rb
spoken_terms = client.create_spoken_terms(
  'Product names',
  [DeepL::Resources::SpokenTermsEntries.new('en', ['DeepL', 'webhook'])]
)

puts spoken_terms.class
# => DeepL::Resources::SpokenTerms
puts spoken_terms.spoken_terms_id
# => 'a74d88fb-ed2a-4943-a664-a4512398b994'
puts spoken_terms.creation_time.class
# => Time
puts spoken_terms.term_lists.first.entry_count
# => 2
```

`creation_time` is `nil` if the API returns a malformed timestamp. List all
collections or fetch one with `list_spoken_terms` and `get_spoken_terms`:

```rb
collections = client.list_spoken_terms
spoken_terms = client.get_spoken_terms 'a74d88fb-ed2a-4943-a664-a4512398b994'
```

`update_spoken_terms` renames a collection and/or merges terms into the list of
each given language. Arguments that are not given are not sent:

```rb
client.update_spoken_terms(spoken_terms, name: 'Renamed')
client.update_spoken_terms(spoken_terms, name: 'Renamed',
                                         extra_body_parameters: { example_param: 'value' })
updated = client.update_spoken_terms(
  spoken_terms, term_lists: [{ lang: 'en', entries: ['authentication'] }]
)
puts updated.term_lists.first.entry_count
# => 3
```

To read the terms of one language, use `get_spoken_terms_entries`:

```rb
entries = client.get_spoken_terms_entries(spoken_terms, 'en')
puts entries.entries.inspect
# => ["DeepL", "authentication", "webhook"]
```

`replace_spoken_terms_list` replaces the terms of one language, or adds the list
if the language is new. It takes one `DeepL::Resources::SpokenTermsEntries` or a
hash with `:lang` and `:entries`:

```rb
term_list = client.replace_spoken_terms_list(
  spoken_terms, DeepL::Resources::SpokenTermsEntries.new('en', ['API'])
)
puts term_list.class
# => DeepL::Resources::SpokenTermsList
puts term_list.entry_count
# => 1
```

To delete the list of one language or the entire collection (both return `nil`):

```rb
client.delete_spoken_terms_list(spoken_terms, 'de')
client.delete_spoken_terms(spoken_terms)
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

### Style profiles

A style profile bundles glossaries, style rule lists and translation memories under one
name. `DeepL::Client` manages them with `create_style_profile`, `get_style_profile`,
`list_style_profiles`, `update_style_profile` and `delete_style_profile`. The last three
take a style profile ID string or a `DeepL::Resources::StyleProfile` object; the ID of a
profile is `style_profile_id`.

#### Creating a style profile

Only the name is required. The optional keywords are `description`, `industry`,
`glossary_ids`, `style_rule_ids`, `translation_memory_ids` and
`glossary_priority_order_enabled` (when `true`, the order of `glossary_ids` sets priority).
The component lists take IDs or the resource objects (`Glossary`, `MultilingualGlossary`,
`StyleRule`, `TranslationMemory`), which are sent as their IDs. If any component cannot be
used, the request fails and no style profile is created. `extra_body_parameters` adds
fields to the request body.

```rb
client = DeepL::Client.new(ENV.fetch('DEEPL_AUTH_KEY'))

# Only a name
profile = client.create_style_profile('Legal, German')

# With components
profile = client.create_style_profile(
  'Legal, German',
  description: 'Contract wording for the German market.',
  industry: 'Legal',
  glossary_ids: ['YOUR_GLOSSARY_ID'],
  style_rule_ids: [style_rule],        # a DeepL::Resources::StyleRule
  translation_memory_ids: ['YOUR_TM_ID'],
  glossary_priority_order_enabled: true
)
profile.class
# => DeepL::Resources::StyleProfile
profile.style_profile_id
# => "3f1c9d0e-7a24-4b58-9c31-8f0e5d2a1b47"
profile.style_rule_ids
# => ["YOUR_STYLE_ID"]
profile.creation_time.class
# => Time
```

`description` and `industry` are `nil` when the style profile has none.

#### Retrieving and listing style profiles

`list_style_profiles` returns an array of style profiles, one page at a time. It accepts
`page:` (0-indexed, default 0) and `page_size:` (default 10; values above 100 are reduced to
100).

```rb
profile = client.get_style_profile('YOUR_STYLE_PROFILE_ID')

profiles = client.list_style_profiles
profiles = client.list_style_profiles(page: 1, page_size: 100)
```

#### Updating a style profile

`update_style_profile` takes the same keywords as `create_style_profile`, plus `name`.
Keywords you leave out (or set to `nil`) are not sent and leave the field unchanged. An
empty string clears `description` or `industry`. A component list you send replaces the
linked list in full; an empty array unlinks all components of that kind.

```rb
updated = client.update_style_profile(
  'YOUR_STYLE_PROFILE_ID',
  name: 'Legal, German (2026)',
  industry: 'Legal',
  description: '',    # clears the description
  style_rule_ids: []  # unlinks all style rule lists
)
updated.description
# => nil
```

#### Deleting a style profile

`delete_style_profile` returns `nil`.

```rb
client.delete_style_profile('YOUR_STYLE_PROFILE_ID')
```

#### Using style profiles in translations

Pass the `style_profile` option, a style profile ID string or a `StyleProfile` object, to
`translate_text`, `translate_document` or `translate_document_upload` to apply the
profile's glossaries, style rule lists and translation memories. A component that does not
fit the language pair is left out. The option cannot be combined with `glossary`,
`glossary_id`, `glossary_ids`, `style_rule`, `translation_memory`,
`translation_memory_threshold` or `custom_instructions`; the API rejects such requests.

```rb
translation = client.translate_text('The artist is here.', nil, 'DE', style_profile: profile)
puts translation.text
# => Der Maler ist hier.

client.translate_document('/path/to/document.docx', '/path/to/translated.docx', 'EN', 'DE',
                          style_profile: 'YOUR_STYLE_PROFILE_ID')
```

With documents, an unknown style profile is not rejected at upload: the translation fails
with a `DeepL::Exceptions::DocumentTranslationError` whose message contains
`Style profile not found.`

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

Each usage type is also available as a `DeepL::Resources::Usage::Detail` with `count`,
`limit` and `limit_reached?`: `character`, plus `document` and `team_document` for accounts with
a document limit. `any_limit_reached?` checks `character`, `document` and `team_document`:

```rb
usage = DeepL.usage

puts 'Translation limit reached.' if usage.any_limit_reached?
puts "Document usage: #{usage.document}" if usage.document
# => Document usage: 5 of 10
```

For API Pro users, the response also contains this API key's usage, speech usage, the billing
period and a per-product breakdown. These fields are `nil` when the response does not contain
them (e.g. for API Free users). `any_limit_reached?` does not consider them; call
`limit_reached?` on them directly, e.g. `usage.api_key_character.limit_reached?`:

```rb
usage = DeepL.usage

# Characters used by the whole account vs. by this API key
puts "account: #{usage.character}"
# => account: 5947223 of 1000000000000
puts "this key: #{usage.api_key_character}"
# => this key: 636 of 1000000000000

puts usage.speech_to_text_minutes   # => 30 of 600
puts usage.speech_to_speech_minutes # => 12 of 600
puts usage.start_time               # => 2025-05-13 09:18:42 UTC (Time)
puts usage.end_time                 # => 2025-06-13 09:18:42 UTC (Time)

usage.products&.each do |product|
  # product_type and billing_unit are plain strings, e.g. 'translate' and 'characters'
  puts "#{product.product_type}: key #{product.api_key_unit_count}, " \
       "account #{product.account_unit_count} #{product.billing_unit}"
end
# => translate: key 636, account 5941580 characters
```

### Translate documents

To translate a document, use the `translate_document` method of `DeepL::Client`. It uploads
the document, waits until the translation is done and writes the translated document to the
output path, which must not exist yet. It returns the final
`DeepL::Resources::DocumentTranslationStatus`:

```rb
status = client.translate_document('/path/to/spanish_document.pdf',
                                   '/path/to/translated_document.pdf', 'ES', 'EN')
puts status.billed_characters
# => 2045
```

Every failure (also a failed translation) raises `DeepL::Exceptions::DocumentTranslationError`.
Once the upload succeeded, its `document_handle` is set, so you can still query the status and
download the document. `timeout_s:` limits the wait after the upload in seconds; by default
`translate_document` waits until the translation is done or failed:

```rb
begin
  client.translate_document('/path/to/document.docx', '/path/to/translated.docx', 'EN', 'DE',
                            timeout_s: 600, formality: 'more')
rescue DeepL::Exceptions::DocumentTranslationError => e
  puts "Translation failed: #{e.message}, document: #{e.document_handle&.document_id}"
end
```

The steps are also exposed. `translate_document_upload` returns a
`DeepL::Resources::DocumentHandle` (`document_id`, `document_key`).
`translate_document_wait_until_done(handle, timeout_s: nil)` queries the status every 5 seconds
until the translation is done and returns that status; it raises `DeepL::Exceptions::Error`
with the API's error message if the translation fails, and when `timeout_s` expires.
`translate_document_get_status` queries the status once, and `translate_document_download`
writes the translated document, overwriting an existing file; it raises
`DeepL::Exceptions::DocumentNotReadyError` if the translation is not done yet.

```rb
handle = client.translate_document_upload('/path/to/spanish_document.pdf', 'ES', 'EN',
                                          filename: 'report.pdf')
status = client.translate_document_get_status(handle)
puts "#{status.status}, ok: #{status.ok?}, done: #{status.successful?}"
# => translating, ok: true, done: false
client.translate_document_wait_until_done(handle)
client.translate_document_download(handle, '/path/to/translated_document.pdf')
```

A `DeepL::Resources::DocumentTranslationStatus` has `document_id`, `status` (a string;
`DeepL::Constants::DocumentStatusCode` has the values `QUEUED`, `TRANSLATING`, `DONE` and
`ERROR`), `seconds_remaining`, `billed_characters` and `error_message`, and the predicates
`successful?` (done), `error?` (failed), `ok?` (not failed, also while queued or translating)
and `finished?` (done or failed).

With the deprecated module-level API, the same methods are `DeepL.document.translate_document`,
`upload`, `get_status` and `download`, which take the filename as a positional parameter and
optional additional headers. `DeepL.document.translate_document` waits until the translation is
done or failed and returns the final status; the deprecated configuration setting
`max_doc_status_queries` limits the number of status requests. The deprecated
`DocumentHandle#wait_until_document_translation_finished` returns the final status also when
the translation failed.

```rb
doc_handle = DeepL.document.upload('/path/to/spanish_document.pdf', 'ES', 'EN')
doc_status = doc_handle.wait_until_document_translation_finished
DeepL.document.download(doc_handle, '/path/to/translated_document.pdf') unless doc_status.error?
```

You can also pass additional options to document translation methods, including `extra_body_parameters`:

```rb
doc_handle = client.translate_document_upload('/path/to/spanish_document.pdf', 'ES', 'EN',
                                              formality: 'more',
                                              extra_body_parameters: { example_param: 'true' })
```

Document translation options include:

- `filename` (`DeepL::Client` only): the file name sent with the upload, including its
  extension. Defaults to the base name of the input path.
- `formality`: same as for text translation.
- `glossary` / `glossary_ids`: see the glossary sections above. `glossary_id` is deprecated,
  use `glossary`.
- `output_format`: file extension of the desired output format, e.g. `'pdf'` to translate
  a `docx` into a PDF.
- `enable_watermark`: `true` adds a "Translated by DeepL" watermark to the translated
  document. The API supports it only for `docx` and `pdf` output and ignores it for other
  formats. When not set, the parameter is not sent.
- `style_rule`, `style_profile`, `translation_memory`, `translation_memory_threshold`:
  same as in text translation; see the style rules, style profiles and translation memory
  sections above.

```rb
client.translate_document('/path/to/document.docx', '/path/to/translated.pdf', 'EN', 'DE',
                          output_format: 'pdf', enable_watermark: true)
```

The `extra_body_parameters` option allows you to pass arbitrary parameters in the request body. This can be used to access beta features by adding new parameters, or to override built-in parameters (such as `target_lang`, `source_lang`, etc.) for testing purposes.

### Admin API

The Admin API lets you manage the developer keys of your organization and retrieve usage analytics. It requires an admin API key, which you can create in the "Admin API Keys" tab of your DeepL account. Admin keys cannot be used for translation, and developer keys cannot access the Admin API: the API rejects a wrong key with `DeepL::Exceptions::AuthorizationFailed`.

Create a `DeepL::AdminClient` with your admin key. It is independent of `DeepL.configure`, does not read the `DEEPL_AUTH_KEY` and `DEEPL_SERVER_URL` environment variables, and uses the `https://api.deepl.com` server by default. The admin key is trimmed. It also accepts the `server_url:`, `headers:`, `max_retries:`, `timeout:`, `proxy:`, `send_platform_info:`, `app_info:`, `http_client_options:` and `logger:` keyword arguments of [`DeepL::Client`](#creating-a-client); without `server_url:` it uses `https://api.deepl.com`, also for keys ending in `:fx`.

```rb
admin_client = DeepL::AdminClient.new('YOUR_ADMIN_KEY')
```

#### Managing developer keys

```rb
key = admin_client.create_developer_key(label: 'Staging Team Key')
puts "Created #{key.label} (#{key.key_id})"

admin_client.list_developer_keys.each do |developer_key|
  puts "#{developer_key.label}: deactivated=#{developer_key.deactivated?}"
end

key = admin_client.rename_developer_key(key, 'Production Team Key')

# Changes only the given limits; the others keep their current value.
# nil removes a limit (unlimited) and 0 blocks that usage.
key = admin_client.set_developer_key_usage_limits(key, characters: 500_000,
                                                       speech_to_text_milliseconds: 60_000)
key = admin_client.set_developer_key_usage_limits(key, speech_to_speech_milliseconds: nil)

# Deactivation is permanent.
admin_client.deactivate_developer_key(key)
```

`rename_developer_key`, `set_developer_key_usage_limits` and `deactivate_developer_key` accept either a key ID or a `DeepL::Resources::DeveloperKey` object and return the updated `DeepL::Resources::DeveloperKey`. `set_developer_key_usage_limits` accepts `characters:`, `speech_to_text_milliseconds:` and `speech_to_speech_milliseconds:`. `create_developer_key` takes the label as the `label:` keyword argument; without it the API labels the key "DeepL API Key". Labels and limits are sent as given and validated by the API. `create_developer_key`, `deactivate_developer_key`, `rename_developer_key` and `set_developer_key_usage_limits` also accept `extra_body_parameters:`, a hash added to the request body last that replaces fields of the same name. A response without a `key_id` raises `DeepL::Exceptions::Error`. `label` and `usage_limits` are `nil` when the response does not contain them.

A failed `create_developer_key` request is retried only after HTTP 429, a DNS resolution error or a connection timeout, when the API cannot have created the key. Other requests are retried like all other requests of the library.

#### Retrieving usage analytics

`get_usage_analytics` returns a `DeepL::Resources::AdminUsageReport` for a date range. Dates are UTC calendar days, and both the start day and the end day are included. They can be `Date`, `Time` or `DateTime` objects or `YYYY-MM-DD` strings. For `Time` and `DateTime` values the SDK sends the UTC date of that moment, so `Time.new(2026, 10, 20, 0, 0, 0, '+02:00')` is sent as `2026-10-19`. An invalid date raises `ArgumentError` without sending a request. The API requires the end date to be after the start date, so a report covers at least two days, and at most 366 days after it; otherwise both analytics methods raise `DeepL::Exceptions::BadRequest`. Use `group_by:` to break the usage down by key (`DeepL::Constants::AdminUsageGroupBy::KEY`, see `key_usages`) or by key and day (`DeepL::Constants::AdminUsageGroupBy::KEY_AND_DAY`, see `key_and_day_usages`). The `group_by` of the report is the raw string the API returns. The usage breakdowns include `speech_to_text_minutes` and `speech_to_speech_minutes`.

```rb
report = admin_client.get_usage_analytics('2026-06-01', '2026-07-01',
                                          group_by: DeepL::Constants::AdminUsageGroupBy::KEY)
puts "Total characters: #{report.total_usage.total_characters}"
report.key_usages.each do |key_usage|
  puts "#{key_usage.api_key_label}: #{key_usage.usage.total_characters}"
end
```

`get_custom_tag_usage_analytics` returns a `DeepL::Resources::CustomTagUsageReport` with the usage per custom tag, for a date range with the same limits. Use `aggregate_by:` to choose between the whole period (`DeepL::Constants::CustomTagUsageAggregateBy::PERIOD`, the default) and per-day usage (`DeepL::Constants::CustomTagUsageAggregateBy::DAY`). The results are paginated: pass the `next_page` value of a report as `page:` to get the next page. The `aggregate_by` of a custom tag report is the raw string the API returns.

```rb
page = nil
loop do
  report = admin_client.get_custom_tag_usage_analytics('2026-06-01', '2026-07-01', page: page)
  report.usage.each do |tag_usage|
    puts "#{tag_usage.custom_tag}: #{tag_usage.breakdown.total_characters}"
  end
  break if report.next_page.nil?

  page = report.next_page
end
```

### Sending additional HTTP headers

`DeepL::Client.new(key, headers: { 'X-DeepL-Reporting-Tag' => 'my-tag' })` sends the headers
with every DeepL API request of that client. With the module-level API, you can pass additional HTTP headers to `translate`, `rephrase`, `correct`, and the
`document` methods. For example, to send the `X-DeepL-Reporting-Tag` header
for usage reporting (see the [cookbook entry](https://developers.deepl.com/docs/learning-how-tos/cookbook/sending-custom-reporting-tags-from-client-libraries)):

```rb
additional_headers = { 'X-DeepL-Reporting-Tag' => 'my-tag' }
translation = DeepL.translate 'Hello, world!', 'EN', 'DE', {}, additional_headers
rephrased = DeepL.rephrase 'Hello, world!', 'EN', nil, nil, {}, additional_headers
corrected = DeepL.correct 'Hello, world!', 'EN', {}, additional_headers
```

### Handle exceptions

You can capture and process exceptions that may be raised during API calls. These are all the possible exceptions:

| Exception class | Description |
| --------------- | ----------- |
| `DeepL::Exceptions::AuthorizationFailed` | The authorization process has failed. Check your `auth_key` value. |
| `DeepL::Exceptions::BadRequest` | Something is wrong in your request. Check `exception.message` for more information. |
| `DeepL::Exceptions::ConnectionError` | No HTTP response after all retries (DNS, connection, TLS or timeout failure). The original exception is `exception.cause`. |
| `DeepL::Exceptions::DocumentNotReadyError` | A subclass of `ServerError`: HTTP 503 on a document download, the translated document is not ready yet. |
| `DeepL::Exceptions::DocumentTranslationError` | An error occured during document translation. Check `exception.message` for more information; `exception.document_handle` is the handle of the uploaded document, `nil` if the upload failed. |
| `DeepL::Exceptions::LimitExceeded` | You've reached the API's call limit. |
| `DeepL::Exceptions::QuotaExceeded` | You've reached the API's character limit. |
| `DeepL::Exceptions::RequestError` | Any other HTTP error status. Its message contains the status and the API's message; check `exception.response` and `exception.request` for more information. |
| `DeepL::Exceptions::NotSupported` | Deprecated, no longer raised by the library. |
| `DeepL::Exceptions::RequestEntityTooLarge` | Your request is too large, reduce the amount of data you are sending. The API has a request size limit of 128 KiB. |
| `DeepL::Exceptions::ServerError` | An error occured in the DeepL API (HTTP 5xx), raised after all retries. |

All of them are subclasses of `DeepL::Exceptions::Error`, which is also raised for a response
that cannot be parsed. Errors of an HTTP response carry the status as an `Integer` in
`exception.http_status_code` (`nil` otherwise).

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

### Retries and timeouts

Requests that fail with HTTP 429, any 5xx status or a network failure (DNS, refused or reset
connection, TLS error, timeout) are retried up to `max_retries:` times (default 5) with
exponential backoff. Each attempt has a timeout of `timeout:` seconds (default 10). After the
last retry, network failures raise `DeepL::Exceptions::ConnectionError`.
`AdminClient#create_developer_key` is only retried when the request was not sent (HTTP 429,
DNS failure, refused connection or connection timeout). With the module-level API, set
`config.max_network_retries` and `config.timeout`.

### Proxy configuration

Pass a proxy URL to the client:

```rb
client = DeepL::Client.new(auth_key, proxy: 'http://user:password@localhost:3128')
```

`DeepL::HTTPClientOptions` also takes the proxy as a URL or as a hash with `proxy_addr` and
`proxy_port`, together with certificate, SSL verification and timeout options. With the
module-level API, a session needs to be used; the proxy is configured as part of the HTTP client options:

```rb
client_options = HTTPClientOptions.new({ 'proxy_addr' => 'http://localhost', 'proxy_port' => 80 })
deepl.with_session(client_options) do |session|
  # ...
end
```

### Anonymous platform information

By default, we send some basic information about the platform the client library is running on with each request, see [here for an explanation](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/User-Agent). This data is completely anonymous and only used to improve our product, not track any individual users. If you do not wish to send this data, create the client with `send_platform_info: false`, or with the module-level API set the `send_platform_info` flag in the configuration to `false` like so:

```rb
deepl.configure({}, nil, nil, false) do |config|
  # ...
end
```

You can also completely replace the `User-Agent` header with `headers: { 'User-Agent' => 'myCustomUserAgent' }`, or with the module-level API like so:

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
client = DeepL::Client.new(auth_key, app_info: { app_name: 'MyTranslationPlugin',
                                                 app_version: '1.0.1' })
```

With the module-level API:

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

There are two suites of specs, which must run in separate processes:

- `spec/offline` tests options, validation, errors, retries and polling against intercepted
  requests (WebMock). It needs no key and no network:

  ```
  bundle exec rspec spec/offline
  ```

- `spec/real_api` sends every endpoint once to the real API. Set `DEEPL_AUTH_KEY` to a test key,
  `DEEPL_ADMIN_KEY` to an admin key for the Admin API specs, and `DEEPL_SERVER_URL` if the keys
  are not for the default server. The specs create resources named `sdktest-ruby-...` and delete
  them again; developer keys cannot be deleted and are deactivated instead. The Admin API spec creates a key, renames it, sets its limits and deactivates it:

  ```
  DEEPL_AUTH_KEY=... DEEPL_ADMIN_KEY=... bundle exec rspec spec/real_api
  ```

To run the offline specs and rubocop, use

```
bundle exec rake test
```

## Acknowledgements

This library was originally developed by [Daniel Herzog](mailto:info@danielherzog.es), we are grateful for his contributions. Beginning with v3.0.0, DeepL took over development and officially supports and maintains the library together with Daniel.