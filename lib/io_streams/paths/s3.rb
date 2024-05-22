require "uri"

module IOStreams
  module Paths
    class S3 < IOStreams::Path
      attr_reader :bucket_name, :options

      # Largest file size supported by the S3 copy object api.
      S3_COPY_OBJECT_SIZE_LIMIT = 5 * 1024 * 1024 * 1024

      # When an upload file exceeds this size, use a multipart file upload.
      MULTIPART_UPLOAD_SIZE = 5 * 1024 * 1024

      # Arguments:
      #
      # url: [String]
      #   Prefix must be: `s3://`
      #   followed by bucket name,
      #   followed by key.
      #   Examples:
      #     s3://my-bucket-name/file_name.txt
      #     s3://my-bucket-name/some_path/file_name.csv
      #
      # access_key_id: [String]
      #   AWS Access Key Id to use to access this bucket.
      #
      # secret_access_key: [String]
      #   AWS Secret Access Key Id to use to access this bucket.
      #
      # region: [String]
      #   The AWS region to connect to.
      #   Defaults to region set in environment variable, or credential files.
      #
      # client: [Aws::S3::Client | Hash]
      #   Supply the AWS S3 Client instance to use for this path.
      #   Or, when a Hash, build a new client using the hash parameters.
      #
      #   Example:
      #     client = Aws::S3::Client.new(endpoint: "https://s3.test.com")
      #     IOStreams::Paths::S3.new(client: client)
      #
      #   Example:
      #     IOStreams::Paths::S3.new(client: { endpoint: "https://s3.test.com" })
      #
      # Writer specific options:
      #
      # @option params [String] :acl
      #   The canned ACL to apply to the object.
      #
      # @option params [String] :cache_control
      #   Specifies caching behavior along the request/reply chain.
      #
      # @option params [String] :content_disposition
      #   Specifies presentational information for the object.
      #
      # @option params [String] :content_encoding
      #   Specifies what content encodings have been applied to the object and
      #   thus what decoding mechanisms must be applied to obtain the media-type
      #   referenced by the Content-Type header field.
      #
      # @option params [String] :content_language
      #   The language the content is in.
      #
      # @option params [Integer] :content_length
      #   Size of the body in bytes. This parameter is useful when the size of
      #   the body cannot be determined automatically.
      #
      # @option params [String] :content_md5
      #   The base64-encoded 128-bit MD5 digest of the part data. This parameter
      #   is auto-populated when using the command from the CLI. This parameted
      #   is required if object lock parameters are specified.
      #
      # @option params [String] :content_type
      #   A standard MIME type describing the format of the object data.
      #
      # @option params [Time,DateTime,Date,Integer,String] :expires
      #   The date and time at which the object is no longer cacheable.
      #
      # @option params [String] :grant_full_control
      #   Gives the grantee READ, READ\_ACP, and WRITE\_ACP permissions on the
      #   object.
      #
      # @option params [String] :grant_read
      #   Allows grantee to read the object data and its metadata.
      #
      # @option params [String] :grant_read_acp
      #   Allows grantee to read the object ACL.
      #
      # @option params [String] :grant_write_acp
      #   Allows grantee to write the ACL for the applicable object.
      #
      # @option params [Hash<String,String>] :metadata
      #   A map of metadata to store with the object in S3.
      #
      # @option params [String] :server_side_encryption
      #   The Server-side encryption algorithm used when storing this object in
      #   S3 (e.g., AES256, aws:kms).
      #
      # @option params [String] :storage_class
      #   The type of storage to use for the object. Defaults to 'STANDARD'.
      #
      # @option params [String] :website_redirect_location
      #   If the bucket is configured as a website, redirects requests for this
      #   object to another object in the same bucket or to an external URL.
      #   Amazon S3 stores the value of this header in the object metadata.
      #
      # @option params [String] :sse_customer_algorithm
      #   Specifies the algorithm to use to when encrypting the object (e.g.,
      #   AES256).
      #
      # @option params [String] :sse_customer_key
      #   Specifies the customer-provided encryption key for Amazon S3 to use in
      #   encrypting data. This value is used to store the object and then it is
      #   discarded; Amazon does not store the encryption key. The key must be
      #   appropriate for use with the algorithm specified in the
      #   x-amz-server-side-encryption-customer-algorithm header.
      #
      # @option params [String] :sse_customer_key_md5
      #   Specifies the 128-bit MD5 digest of the encryption key according to
      #   RFC 1321. Amazon S3 uses this header for a message integrity check to
      #   ensure the encryption key was transmitted without error.
      #
      # @option params [String] :ssekms_key_id
      #   Specifies the AWS KMS key ID to use for object encryption. All GET and
      #   PUT requests for an object protected by AWS KMS will fail if not made
      #   via SSL or using SigV4. Documentation on configuring any of the
      #   officially supported AWS SDKs and CLI can be found at
      #   http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingAWSSDK.html#specify-signature-version
      #
      # @option params [String] :ssekms_encryption_context
      #   Specifies the AWS KMS Encryption Context to use for object encryption.
      #   The value of this header is a base64-encoded UTF-8 string holding JSON
      #   with the encryption context key-value pairs.
      #
      # @option params [String] :request_payer
      #   Confirms that the requester knows that she or he will be charged for
      #   the request. Bucket owners need not specify this parameter in their
      #   requests. Documentation on downloading objects from requester pays
      #   buckets can be found at
      #   http://docs.aws.amazon.com/AmazonS3/latest/dev/ObjectsinRequesterPaysBuckets.html
      #
      # @option params [String] :tagging
      #   The tag-set for the object. The tag-set must be encoded as URL Query
      #   parameters. (For example, "Key1=Value1")
      #
      # @option params [String] :object_lock_mode
      #   The object lock mode that you want to apply to this object.
      #
      # @option params [Time,DateTime,Date,Integer,String] :object_lock_retain_until_date
      #   The date and time when you want this object's object lock to expire.
      #
      # @option params [String] :object_lock_legal_hold_status
      #   The Legal Hold status that you want to apply to the specified object.
      def initialize(url, client: nil, access_key_id: nil, secret_access_key: nil, region: nil, **args)
        Utils.load_soft_dependency("aws-sdk-s3", "AWS S3") unless defined?(::Aws::S3::Client)

        uri = Utils::URI.new(url)
        raise "Invalid URI. Required Format: 's3://<bucket_name>/<key>'" unless uri.scheme == "s3"

        @bucket_name = uri.hostname
        key          = uri.path.sub(%r{\A/}, "")

        if client && !client.is_a?(Hash)
          @client = client
        else
          @client_options                     = client.is_a?(Hash) ? client.dup : {}
          @client_options[:access_key_id]     = access_key_id if access_key_id
          @client_options[:secret_access_key] = secret_access_key if secret_access_key
          @client_options[:region]            = region if region
        end

        @options = args
        @options.merge!(uri.query.transform_keys(&:to_sym)) if uri.query

        super(key)
      end

      def to_s
        ::File.join("s3://", bucket_name, path)
      end

      # Does not support relative file names since there is no concept of current working directory
      def relative?
        false
      end

      def delete
        client.delete_object(bucket: bucket_name, key: path)
        self
      rescue Aws::S3::Errors::NotFound
        self
      end

      def exist?
        client.head_object(bucket: bucket_name, key: path)
        true
      rescue Aws::S3::Errors::NotFound
        false
      end

      # Moves this file to the `target_path` by copying it to the new name and then deleting the current file.
      #
      # Notes:
      # - Can copy across buckets.
      # - No stream conversions are applied.
      def move_to(target_path)
        target = copy_to(target_path, convert: false)
        delete
        target
      end

      # Make S3 perform direct copies within S3 itself.
      def copy_to(target_path, convert: true, **args)
        return super(target_path, convert: convert, **args) if convert || (size.to_i >= S3_COPY_OBJECT_SIZE_LIMIT)

        target = IOStreams.new(target_path)
        return super(target, convert: convert, **args) unless target.is_a?(self.class)

        source_name = ::File.join(bucket_name, path)
        client.copy_object(options.merge(bucket: target.bucket_name, key: target.path, copy_source: source_name))
        target
      end

      # Make S3 perform direct copies within S3 itself.
      def copy_from(source_path, convert: true, **args)
        return super(source_path, convert: true, **args) if convert

        source = IOStreams.new(source_path)
        if !source.is_a?(self.class) || (source.size.to_i >= S3_COPY_OBJECT_SIZE_LIMIT)
          return super(source, convert: convert, **args)
        end

        source_name = ::File.join(source.bucket_name, source.path)
        client.copy_object(options.merge(bucket: bucket_name, key: path, copy_source: source_name))
      end

      # S3 logically creates paths when a key is set.
      def mkpath
        self
      end

      def mkdir
        self
      end

      def size
        client.head_object(bucket: bucket_name, key: path).content_length
      rescue Aws::S3::Errors::NotFound
        nil
      end

      # TODO: delete_all

      # Read from AWS S3 file.
      def stream_reader(&block)
        # Since S3 download only supports a push stream, write it to a tempfile first.
        Utils.temp_file_name("iostreams_s3") do |file_name|
          read_file(file_name)

          ::File.open(file_name, "rb") { |io| builder.reader(io, &block) }
        end
      end

      # Shortcut method if caller has a filename already with no other streams applied:
      def read_file(file_name)
        ::File.open(file_name, "wb") do |file|
          client.get_object(options.merge(response_target: file, bucket: bucket_name, key: path))
        end
      end

      # Write to AWS S3
      #
      # Raises [MultipartUploadError] If an object is being uploaded in
      #   parts, and the upload can not be completed, then the upload is
      #   aborted and this error is raised.  The raised error has a `#errors`
      #   method that returns the failures that caused the upload to be
      #   aborted.
      def stream_writer(&block)
        # Since S3 upload only supports a pull stream, write it to a tempfile first.
        Utils.temp_file_name("iostreams_s3") do |file_name|
          result = ::File.open(file_name, "wb") { |io| builder.writer(io, &block) }

          # Upload file only once all data has been written to it
          write_file(file_name)
          result
        end
      end

      # Shortcut method if caller has a filename already with no other streams applied:
      def write_file(file_name)
        if ::File.size(file_name) > MULTIPART_UPLOAD_SIZE
          # Use multipart file upload
          s3  = Aws::S3::Resource.new(client: client)
          obj = s3.bucket(bucket_name).object(path)
          obj.upload_file(file_name, options)
        else
          ::File.open(file_name, "rb") do |file|
            client.put_object(options.merge(bucket: bucket_name, key: path, body: file))
          end
        end
      end

      # Notes:
      # - Currently all S3 lookups are recursive as of the pattern regardless of whether the pattern includes `**`.
      def each_child(pattern = "*", case_sensitive: false, directories: false, hidden: false)
        unless block_given?
          return to_enum(__method__, pattern,
                         case_sensitive: case_sensitive, directories: directories, hidden: hidden)
        end

        matcher = Matcher.new(self, pattern, case_sensitive: case_sensitive, hidden: hidden)

        # When the pattern includes an exact file name without any pattern characters
        if matcher.pattern.nil?
          yield(matcher.path) if matcher.path.exist?
          return
        end

        prefix = Utils::URI.new(matcher.path.to_s).path.sub(%r{\A/}, "")
        token  = nil
        loop do
          # Fetches upto 1,000 entries at a time
          resp = client.list_objects_v2(bucket: bucket_name, prefix: prefix, continuation_token: token)
          resp.contents.each do |object|
            next if !directories && object.key.end_with?("/")

            file_name = ::File.join("s3://", resp.name, object.key)
            next unless matcher.match?(file_name)

            yield(self.class.new(file_name), object.to_h)
          end
          token = resp.next_continuation_token
          break if token.nil?
        end
        nil
      end

      # On S3 only files that are completely saved are visible.
      def partial_files_visible?
        false
      end

      # Lazy load S3 client since it takes two seconds to create itself!
      def client
        @client ||= ::Aws::S3::Client.new(@client_options)
      end
    end
  end
end
