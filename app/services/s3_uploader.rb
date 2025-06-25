require 'aws-sdk-s3'

class S3Uploader
  REGION = ENV.fetch('AWS_REGION', 'YOUR_AWS_REGION')
  ACCESS_KEY_ID = ENV.fetch('AWS_ACCESS_KEY_ID', 'YOUR_AWS_ACCESS_KEY_ID')
  SECRET_ACCESS_KEY = ENV.fetch('AWS_SECRET_ACCESS_KEY', 'YOUR_AWS_SECRET_ACCESS_KEY')
  BUCKET = ENV.fetch('AWS_S3_BUCKET', 'YOUR_S3_BUCKET_NAME')

  def self.upload(file, folder: 'uploads')
    s3 = Aws::S3::Resource.new(
      region: REGION,
      access_key_id: ACCESS_KEY_ID,
      secret_access_key: SECRET_ACCESS_KEY
    )
    key = "#{folder}/#{SecureRandom.uuid}_#{file.original_filename}"
    obj = s3.bucket(BUCKET).object(key)
    obj.upload_file(file.path, acl: 'public-read')
    obj.public_url
  rescue => e
    Rails.logger.error("S3 upload failed: #{e.message}")
    nil
  end
end 