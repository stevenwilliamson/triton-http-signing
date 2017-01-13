require "base64"
require "stringio"
require "socket"

module Triton
  module Http
    module Signing


      # This class implements a minimum amount of ssh-agent protocol required
      # to have the agent sign payloads on our behalf.
      # At present the class only supports signing using rsa keys, dsa and ecdsa have not
      # been implemented. However adding this support should not be too difficult
      class Agent

        # Messages identifiers
        SSH2_AGENTC_SIGN_REQUEST = 13
        SSH2_AGENT_SIGN_RESPONSE = 14
        SSH_AGENT_FAILURE = 5


        # This method signs any data passed in using the ssh-agent and returns
        # the binary signature. For rsa keys the signature will be rsa encrypted sha1
        #
        # [data] data to sign
        # [pub_key_path] Path to an ssh public key, the agent will use the corresponding private key
        #
        # Returns an Array containing the signature blob and the ssh signature type
        #
        def sign(data, pub_key_path)

          # Packet format for ssh agent signing request
          # byte			      SSH2_AGENTC_SIGN_REQUEST
          # ssh_string			key_blob
          # ssh_string			data
          # uint32			    flags

          ssh_agent do |c|
            packet = [SSH2_AGENTC_SIGN_REQUEST].pack("C") +
              ssh_string(load_pub_key_data(pub_key_path)) +
              ssh_string(data) +
              [0].pack("N")
            packet = [packet.bytesize].pack("N") + packet

            c.puts(packet)

            # Process the response and extract the signature
            # from the ssh formatted blob were been naive here and just
            # supporting ssh-rsa for now.
            response = recv_ssh2_agentc_sign_resp(c)
            if response =~ /ssh-rsa/
              return response.split("ssh-rsa")[1].byteslice(4..-1), "ssh-rsa"
            else
              raise AgentException, "Unsupported signature type returned by ssh-agent, only ssh-rsa supported"
            end
          end
        end

        # opens the ssh-agent socket and yeilds
        # we memorise the open socket to avoid opening it for every
        # request
        def ssh_agent
          if ENV['SSH_AUTH_SOCK'] == nil
            raise AgentException, "Can't find ssh agent socket no SSH_AUTH_SOCK env variable set"
          end
          @ssh_agent_sock ||= UNIXSocket.open(ENV['SSH_AUTH_SOCK'])
          yield @ssh_agent_sock
        end

        # Returns an ssh string as defined in RFC 4251
        def ssh_string(data)
          return [data.bytesize].pack("N") + data
        end

        # Decode a string from an ssh-agent packet defined in RFC 4251
        def decode_ssh_string(data)
          str_len = data.read(4).unpack("N").first()
          if str_len < 1
            raise AgentException, "Invalid short string in packet"
          end
          data.read(str_len)
        end

        # Loads data for an ssh public key, returns it
        # base64 encoded minus the type header
        def load_pub_key_data(path)
          File.open(path) do |f|
            return Base64.decode64(f.read.split(' ')[1])
          end
        end

        # Process a ssh2 signing request response
        def recv_ssh2_agentc_sign_resp(socket)
          msg = StringIO.new(recv_packet(socket))
          msg_type = msg.read(1).unpack("C").first

          if msg_type == SSH2_AGENT_SIGN_RESPONSE
            signature_blob = decode_ssh_string(msg)
          elsif msg_type == SSH_AGENT_FAILURE
            raise AgentException, "Error response from ssh agent received"
          else
            raise AgentException, "Unexpected response from ssh agent received"
          end

          return signature_blob
        end

        # Read a packet off the wire
        def recv_packet(socket)
          # read the size and then the rest of the packet
          msg_size = socket.read(4).unpack("N").first

          if msg_size > 1
            packet = socket.read(msg_size)
          else
            raise AgentException, "Invalid short packet received from ssh-agent"
          end

          return packet
        end

        private :recv_ssh2_agentc_sign_resp, :recv_packet
      end
    end
  end
end
