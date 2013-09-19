module Magensa
  DECRYPT_ACTION = "DecryptRSV201"

  class Decrypter
    attr_accessor :options, :encrypted_data

    def initialize(username, password, options)
      @hostID = username
      @hostPwd = password
      self.options = options
    end

    def decrypt(encrypted_data)
      if encrypted_data[:track]
        @encrypted_data = self.class.parse(encrypted_data[:track])
      else
        @encrypted_data = self.class.validate_data(encrypted_data)
      end

      client.transmit(DECRYPT_ACTION, request_body)
    end

    def client
      @client ||= Client.new({
        logger: options[:logger],
        production: options[:production] || true,
        mock: options[:mock] || false
      })
    end

    def self.validate_data(encrypted_hash)
      data = encrypted_hash
      data[:first_name] = data[:name].split("/").last
      data[:last_name] = data[:name].split("/").first
      data[:month] = data[:expiration].slice(2,2)
      data[:year] = data[:expiration].slice(0,2)
      data
    end

    def self.parse(encrypted_string)
      data = {}
      parse_array = encrypted_string.split('|')
      data[:track2] = parse_array[3]
      data[:mpstatus] = parse_array[5]
      data[:mp] = parse_array[6]
      data[:device_sn] = parse_array[7]
      data[:ksn] = parse_array[9]

      split = encrypted_string.slice(2, encrypted_string.length-2).split("^")
      data[:brand_identifier] = split[0] if split[0]
      data[:last_four_digits] = split[0].slice(-4, 4) if split[0]
      if split[1]
        data[:first_name] = split[1].split("/").last
        data[:last_name] = split[1].split("/").first
      end
      if split[2]
        data[:month] = split[2].slice(2,2)
        data[:year] = split[2].slice(0,2)
      end
      data
    end

    private
    
      def track2_pan(track2)
        track2.match(/^;(\d+)=/)[1]
      rescue
        nil
      end

      def request_body
        {
          "DecryptRSV201_Input" => {
            "EncTrack2" => @encrypted_data[:track2],
            "EncTrack1" => @encrypted_data[:track1],
            "EncTrack3" => @encrypted_data[:track3],
            "EncMP" => @encrypted_data[:mp],
            "KSN" => @encrypted_data[:ksn],
            "DeviceSN" => @encrypted_data[:device_sn],
            "MPStatus" => @encrypted_data[:mpstatus],
            "CustTranID" => options[:ref_id],
            "HostID" => @hostID,
            "HostPwd" => @hostPwd,
            "OutputFormatCode" => "103",
            "CardType" => "1",
            "EncryptionBlockType" => "1",
            "RegisteredBy" => "BypassLane",
            "FutureInput" => "",
            :order! => ["EncTrack1", "EncTrack2", "EncTrack3", "EncMP", "KSN", "DeviceSN", "MPStatus", "CustTranID", "HostID", "HostPwd", "OutputFormatCode", "CardType", "EncryptionBlockType", "RegisteredBy", "FutureInput"]
          }
        }
      end
  end
end