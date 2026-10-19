# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require 'tmpdir'

# Fixtures shared by the offline and the real-API specs.
module Fixtures
  EXAMPLE_TMX = <<~TMX
    <?xml version="1.0" encoding="UTF-8"?>
    <tmx version="1.4"><header creationtool="deepl-rb-spec" creationtoolversion="1"
      segtype="sentence" o-tmf="plain" adminlang="en" srclang="en" datatype="plaintext"/>
    <body><tu><tuv xml:lang="en"><seg>Segment number 1</seg></tuv>
    <tuv xml:lang="de"><seg>Segment Nummer 1</seg></tuv></tu></body></tmx>
  TMX

  # Every byte value, to check that downloads are written unchanged.
  BINARY_CONTENT = (0..255).map(&:chr).join.b.freeze

  # Writes an example .txt document in +dir+. Returns the input path and a free output path.
  def create_text_document(dir)
    input = File.join(dir, 'example_document.txt')
    File.write(input, 'proton beam')
    [input, File.join(dir, 'output_document.txt')]
  end
end

RSpec.shared_context 'with a temporary directory' do
  let(:temp_dir) { Dir.mktmpdir('deepl-rspec-') }

  after { FileUtils.remove_entry(temp_dir) }
end
