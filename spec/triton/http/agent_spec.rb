require "spec_helper"
require "digest/sha1"

describe Triton::Http::Signing::Agent do

  # To run these tests you will need ssh-agent running and will have had to have
  # loaded the private key from spec/data. We could mock out the calls to the agent
  # but it feels like that would provide little testing value
  context "With running ssh-agent and a valid public and private rsa key" do

    before(:example) do
      # SHA1 hash of the expected signature returned by Agent.sign
      # for the data "test", and the key from spec/data
      @expected_sig_hash = 'a560caffa08950402241b7d428f3530fbbd27d19'
      @agent = Triton::Http::Signing::Agent.new()
    end

    it "can sign data using ssh-rsa alg" do
      signed, alg = @agent.sign("test", "spec/data/id_rsa.pub")
      expect(Digest::SHA1.hexdigest(signed)).to eq(@expected_sig_hash)
      expect(alg).to eq("ssh-rsa")
    end
  end
end
