# Copyright 2024 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'securerandom'
require 'tempfile'

module IntegrationTestUtils # rubocop:disable Metrics/ModuleLength
  EXAMPLE_TEXT = {
    'BG' => 'протонен лъч',
    'CS' => 'protonový paprsek',
    'DA' => 'protonstråle',
    'DE' => 'Protonenstrahl',
    'EL' => 'δέσμη πρωτονίων',
    'EN' => 'proton beam',
    'EN-US' => 'proton beam',
    'EN-GB' => 'proton beam',
    'ES' => 'haz de protones',
    'ET' => 'prootonikiirgus',
    'FI' => 'protonisäde',
    'FR' => 'faisceau de protons',
    'HU' => 'protonnyaláb',
    'ID' => 'berkas proton',
    'IT' => 'fascio di protoni',
    'JA' => '陽子ビーム',
    'KO' => '양성자 빔',
    'LT' => 'protonų spindulys',
    'LV' => 'protonu staru kūlis',
    'NB' => 'protonstråle',
    'NL' => 'protonenbundel',
    'PL' => 'wiązka protonów',
    'PT' => 'feixe de prótons',
    'PT-BR' => 'feixe de prótons',
    'PT-PT' => 'feixe de prótons',
    'RO' => 'fascicul de protoni',
    'RU' => 'протонный луч',
    'SK' => 'protónový lúč',
    'SL' => 'protonski žarek',
    'SV' => 'protonstråle',
    'TR' => 'proton ışını',
    'UK' => 'протонний пучок',
    'ZH' => '质子束'
  }.freeze

  def mock_server?
    ENV.key?('DEEPL_MOCK_SERVER_PORT')
  end

  def mock_proxy_server?
    ENV.key?('DEEPL_MOCK_PROXY_SERVER_PORT')
  end

  def real_server?
    !mock_server?
  end

  def setup
    @input_file = nil
    @input_file_extension = nil
    @output_file = nil
    DeepL.configure do |config|
      config.auth_key = 'your-api-token'
    end
  end

  def teardown
    unless @input_file.nil?
      @input_file.close
      @input_file.unlink
    end
    return if @output_file.nil?

    @output_file.close
    @output_file.unlink
  end

  def example_document_path(document_language)
    setup_example_document(EXAMPLE_TEXT[document_language])
  end

  def example_large_document_path(document_language)
    setup_example_document("#{EXAMPLE_TEXT[document_language]}\n" * 1000)
  end

  def setup_example_document(file_content)
    @input_file_base_name = 'example_input_document' if @input_file_base_name.nil?
    @input_file_extension = '.txt' if @input_file_extension.nil?
    if @input_file.nil?
      @input_file = Tempfile.new([@input_file_base_name, @input_file_extension])
      @input_file.write(file_content)
      @input_file.close
    end
    @input_file.path
  end

  def example_document_translation(document_language)
    EXAMPLE_TEXT[document_language]
  end

  def example_large_document_translation(document_language)
    "#{EXAMPLE_TEXT[document_language]}\n" * 1000
  end

  def output_document_path
    @output_file = Tempfile.new('example_output_document') if @output_file.nil?
    @output_file.path
  end

  # For detailed explanations of these header, check the deepl-mock README.md
  def no_response_header(no_response_count)
    { 'mock-server-session-no-response-count' => no_response_count.to_s,
      'mock-server-session' => SecureRandom.uuid }
  end

  def respond_with_429_header(response_count)
    { 'mock-server-session-429-count' => response_count.to_s,
      'mock-server-session' => SecureRandom.uuid }
  end

  def set_character_limit_header(response_count) # rubocop:disable Naming/AccessorMethodName
    { 'mock-server-session-init-character-limit' => response_count.to_s,
      'mock-server-session' => SecureRandom.uuid }
  end

  def set_document_limit_header(response_count) # rubocop:disable Naming/AccessorMethodName
    { 'mock-server-session-init-document-limit' => response_count.to_s,
      'mock-server-session' => SecureRandom.uuid }
  end

  def set_team_document_limit_header(response_count) # rubocop:disable Naming/AccessorMethodName
    { 'mock-server-session-init-team-document-limit' => response_count.to_s,
      'mock-server-session' => SecureRandom.uuid }
  end

  def fail_docs_header(response_count)
    { 'mock-server-session-doc-failure' => response_count.to_s,
      'mock-server-session' => SecureRandom.uuid }
  end

  def doc_translation_queue_time_header(response_count)
    { 'mock-server-session-doc-queue-time' => response_count.to_s,
      'mock-server-session' => SecureRandom.uuid }
  end

  def doc_translation_translation_time_header(response_count)
    { 'mock-server-session-doc-translate-time' => response_count.to_s,
      'mock-server-session' => SecureRandom.uuid }
  end

  # Makes a translation memory import or export job report its non-terminal status, such as
  # `awaiting_input` for an uploaded import, for the given number of status queries before it
  # completes. Without it a job completes on the first query.
  def tm_job_processing_polls_header(poll_count)
    { 'mock-server-session-tm-job-processing-polls' => poll_count.to_s,
      'mock-server-session' => SecureRandom.uuid }
  end

  def expect_proxy_header(response_count)
    { 'mock-server-session-expect-proxy' => response_count.to_s,
      'mock-server-session' => SecureRandom.uuid }
  end
end

shared_context 'with temp dir' do
  around do |example|
    Dir.mktmpdir('deepl-rspec-') do |dir|
      @temp_dir = dir
      example.run
    end
  end

  attr_reader :temp_dir, :input_file_base_name, :input_file_extension
end

RSpec.configure do |c|
  c.include IntegrationTestUtils
end
