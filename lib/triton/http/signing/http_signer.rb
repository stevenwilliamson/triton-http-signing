require "base64"
require "openssl"
require "triton/http/signing/agent"

module Triton
	module Http
		module Signing
      class HttpSigner

        # Create a HttpSigner object for an account and key
        # combination. Used to generate http-signatures for auth against triton-api
        def initialize(account, public_key_path, signer = Agent.new())
          @public_key_path = public_key_path
          @account = account
          @signer = signer
          @keyid = keyid(public_key_path)
        end

        # Generates a signature header for authentication with cloudapi
        def signature(data)
          sig_string = 'Signature keyId=/%s/keys/%s\",algorithm="%s" %s'
          signature, ssh_alg = Base64.strict_encode64(@agent.sign(data,@public_key_path))

          case ssh_alg
          when "ssh-rsa"
            sig_alg = "rsa-sha1"
          else
            raise ArgumentError, "unsupported ssh signature algorithm"
          end

          return printf(sig_string, account, @keyid, sig_alg, signature)
        end

        # Returns the fingerprint of an SSH public key to be used
        # as the ID in the signature header
        def keyid(public_key_path)
          rsa = OpenSSL::PKey::RSA.new(File.read(File.expand_path(public_key_path)), '')
          str = [7].pack('N') + 'ssh-rsa' + rsa.public_key.e.to_s(0) + rsa.public_key.n.to_s(0)
          OpenSSL::Digest::MD5.hexdigest(str).scan(/../).join(':')
        end

      end
		end
	end
end
