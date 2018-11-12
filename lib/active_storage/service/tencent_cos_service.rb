# tencent cos does not have sdk for ruby
# https://cloud.tencent.com/document/product/436/6474
# TODO wrap cos code as a client lib?
require 'net/http'

module ActiveStorage
  class Service::TencentCOSService < Service
    def initialize(**config)
      @config = config
    end

    def upload(key, io, checksum: nil)
      raise NotImplementedError
    end

    def download(key, &block)
      uri  = URI(url_for(key))
      if block_given?
        instrument :streaming_download, key: key do
          Net::HTTP.get_response(uri, &block)
        end
      else
        instrument :download, key: key do
          Net::HTTP.get(uri)
        end
      end
    end

    def download_chunk(key, range)
      instrument :download_chunk, key: key, range: range do
        uri  = URI(url_for(key))
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |client|
          client.get(uri, Range: "bytes=#{range.begin}-#{range.exclude_end? ? range.end - 1 : range.end}").body
        end
      end
    end

    def delete(key)
      instrument :delete, key: key do
        uri  = URI(url_for(key))
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |client|
          res = client.delete(uri, Authorization: authorization_for(key, 'delete'))
          # res.code == '204'
          res.kind_of?(Net::HTTPSuccess)
        end
      end
    end

    def delete_prefixed(prefix)
      # TODO
      # https://cloud.tencent.com/document/product/436/7734
      # https://cloud.tencent.com/document/product/436/14120

      # prevent destory error
      # raise NotImplementedError
    end

    def exist?(key)
      instrument :exist, key: key do |payload|
        uri = URI(url_for(key))
        answer = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |client|
          res = client.head(uri, Authorization: authorization_for(key, 'head'))
          res.kind_of?(Net::HTTPSuccess)
        end

        payload[:exist] = answer
        answer
      end
    end

    def url(key, expires_in:, filename:, content_type:, disposition:)
      instrument :url, key: key do |payload|
        # TODO url?response-content-disposition=disposition
        generated_url = endpoint_url_for(key)
        payload[:url] = generated_url
        generated_url
      end
    end

    def url_for_direct_upload(key, **)
      instrument :url, key: key do |payload|
        generated_url = url_for(key)
        payload[:url] = generated_url
        generated_url
      end
    end

    def headers_for_direct_upload(key, checksum:, content_type:, content_length:, **)
      {
        'Authorization': authorization_for(key, 'put'),
        'Content-Type': content_type,
        # 'Content-Length': content_length, # refused by browser
        'Content-MD5': checksum,
        'Cache-Control': "max-age=#{max_age}",
      }
    end

    private
      attr_reader :config

      def max_age
        config.fetch(:max_age, 60)
      end

      def path_for(key)
        prefix = config.fetch(:prefix, '')
        "#{prefix}/#{key}"
      end

      def host
        bucket, app_id, region = config.fetch_values(:bucket, :app_id, :region)
        "#{bucket}-#{app_id}.cos.#{region}.myqcloud.com"
      end

      def url_for(key)
        "https://#{host}#{path_for(key)}"
      end

      def endpoint_url_for(key)
        endpoint = config.fetch(:endpoint)
        if endpoint.present?
          "#{endpoint}#{path_for(key)}"
        else
          url_for(key)
        end
      end

      # https://cloud.tencent.com/document/product/436/7778#signature
      def authorization_for(key, method, expires_in=url_expires_in)
        secret_id, secret_key = config.fetch_values(:secret_id, :secret_key)

        time = "#{Time.now.to_i};#{expires_in.after.to_i}"
        # URI.encode(HttpHeaders)?
        sign_key = OpenSSL::HMAC.hexdigest('sha1', secret_key, time)
        http_string =  "#{method}\n#{path_for(key)}\n\nhost=#{host}\n"
        string_to_sign = "sha1\n#{time}\n#{OpenSSL::Digest::SHA1.hexdigest(http_string)}\n"
        sign = OpenSSL::HMAC.hexdigest('sha1', sign_key, string_to_sign)

        {
          'q-sign-algorithm': 'sha1',
          'q-ak': secret_id,
          'q-sign-time': time,
          'q-key-time': time,
          'q-header-list': 'host',
          'q-url-param-list': '',
          'q-signature': sign,
        }.map {|k, v| "#{k}=#{v}"}.join('&')
        # value should not escaped, `to_query` is not working here
      end
  end
end
