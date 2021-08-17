module Intrigue
  module Task
    class AwsS3GatherBuckets < BaseTask
      def self.metadata
        {
          name: 'aws_s3_gather_buckets',
          pretty_name: 'AWS S3 Gather Buckets',
          authors: ['maxim'],
          description: 'This task enumerates S3 Buckets belonging to an authenticated account.',
          references: [],
          type: 'discovery',
          passive: true,
          allowed_types: ['String', 'AwsCredential'],
          example_entities: [{ 'type' => 'String', 'details' => { 'name' => '__IGNORE__', 'default' => '__IGNORE__' } }],
          allowed_options: [],
          created_types: ['AwsS3Bucket']
        }
      end

      ## Default method, subclasses must override this
      def run
        super

        # Get the AWS Credentials
        aws_access_key, aws_secret_key = get_aws_keys_from_entity_type(_get_entity_type_string)
        return unless aws_access_key && aws_secret_key
        
        # when querying account for buckets; region doesn't make a difference so we use us-east-1 by default
        _log "Getting S3 buckets..."
        s3 = Aws::S3::Resource.new(region: 'us-east-1', access_key_id: aws_access_key, secret_access_key: aws_secret_key)

        begin
          bucket_names = s3.buckets.collect(&:name) # collect the buckets from the account
        rescue Aws::S3::Errors::InvalidAccessKeyId, Aws::S3::Errors::SignatureDoesNotMatch
          _log_error 'Invalid AWS Keys.'
          return
        rescue Aws::S3::Errors::AccessDenied, Aws::S3::Errors::AllAccessDisabled
          _log_error 'Credentials lack permissions to list buckets.'
          return
        end

        return if bucket_names.nil?

        _log_good "Retrieved #{bucket_names.size} buckets."

        bucket_names.each do |name|
          en = _create_entity 'AwsS3Bucket', {
            'name' => name, # use the new virtual host path since path style will be deprecated,
            'bucket_name' => name,
            'bucket_uri' => "#{name}.s3.amazonaws.com",
          }

          # record how we retrieved the s3 bucket
          if _get_entity_type_string == 'AwsCredential'
            en.set_detail("source", "aws_credential")
            en.set_sensitive_detail("source_entity_id", @entity.id)
          elsif _get_entity_type_string == 'String'
            en.set_detail("source", "configuration")
          end 
        end
      end
    end
  end
end
