# Copyright 2026 DeepL SE (https://www.deepl.com)
# Use of this source code is governed by an MIT
# license that can be found in the LICENSE file.
# frozen_string_literal: true

require_relative 'offline_helper'

describe DeepL::Deprecation do
  around do |example|
    enabled = Warning[:deprecated]
    example.run
  ensure
    Warning[:deprecated] = enabled
  end

  it "prints nothing while Ruby's deprecation warnings are off" do
    Warning[:deprecated] = false

    expect { described_class.warn_once('spec-off', 'm') }.not_to output.to_stderr
  end

  it 'warns in the deprecated category when they are on' do
    Warning[:deprecated] = true

    if RUBY_VERSION >= '3.0'
      expect(Warning).to receive(:warn).with(/m/, category: :deprecated)
      described_class.warn_once('spec-on', 'm')
    else
      expect { described_class.warn_once('spec-on', 'm') }.to output(/m/).to_stderr
    end
  end
end
