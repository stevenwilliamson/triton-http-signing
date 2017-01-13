require "spec_helper"

describe Triton::Http::Signing do
  it "has a version number" do
    expect(Triton::Http::Signing::VERSION).not_to be nil
  end
end
