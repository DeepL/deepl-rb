# Copyright 2025 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

module ManagedTranslationMemory
  # A minimal, valid TMX document to import in the translation memory specs.
  EXAMPLE_TMX = <<~TMX
    <?xml version="1.0" encoding="UTF-8"?>
    <tmx version="1.4">
      <header creationtool="deepl-rb-spec" srclang="de" segtype="sentence"
              adminlang="en" datatype="plaintext" o-tmf="TMX"/>
      <body>
        <tu>
          <tuv xml:lang="de"><seg>Quelltext Nummer 0</seg></tuv>
          <tuv xml:lang="en"><seg>Source text number 0</seg></tuv>
        </tu>
      </body>
    </tmx>
  TMX

  # Imports the TMX file at +input_file_path+ and yields the finished import job, deleting the
  # resulting translation memory afterwards.
  def with_managed_translation_memory(input_file_path, display_name: nil)
    job = DeepL.translation_memories.import_from_filepath(input_file_path,
                                                          display_name: display_name)
    yield job
  ensure
    begin
      DeepL.translation_memories.destroy(job.result.translation_memory_id) if job
    rescue StandardError
      nil
    end
  end

  # Creates an import job for the TMX file at +input_file_path+ through +translation_memories+
  # and uploads the file, then returns the created import. The mock server keeps the job in the
  # `awaiting_input` status for +processing_polls+ status queries before completing it, standing
  # in for the live API detecting the upload asynchronously.
  def create_uploaded_import(translation_memories, input_file_path, processing_polls:)
    file_content = File.binread(input_file_path)
    created = translation_memories.create_import(
      File.basename(input_file_path), file_content.bytesize,
      additional_headers: tm_job_processing_polls_header(processing_polls)
    )
    translation_memories.upload_file(created, file_content)
    created
  end

  # Writes the example TMX document to +path+ and returns the path.
  def write_example_tmx(path)
    File.write(path, EXAMPLE_TMX)
    path
  end
end
