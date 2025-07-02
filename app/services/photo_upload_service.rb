class PhotoUploadService
  class << self
    # Attach photo to a model instance using Active Storage
    # Usage: PhotoUploadService.attach_photo(workspace, params[:photo])
    def attach_photo(model_instance, photo_file)
      return { success: false, error: 'No photo provided' } if photo_file.blank?
      return { success: false, error: 'Invalid file type' } unless valid_image?(photo_file)
      return { success: false, error: 'File too large' } unless valid_size?(photo_file)

      begin
        model_instance.photo.attach(photo_file)
        { success: true, message: 'Photo uploaded successfully' }
      rescue => e
        Rails.logger.error("Photo upload failed: #{e.message}")
        { success: false, error: 'Upload failed. Please try again.' }
      end
    end

    # Get photo URL (works in both development and production)
    def photo_url(model_instance)
      return nil unless model_instance.photo.attached?

      if Rails.env.development?
        Rails.application.routes.url_helpers.rails_blob_url(model_instance.photo, host: 'localhost:3000')
      else
        model_instance.photo.url
      end
    end

    # Check if model has photo attached
    def photo_attached?(model_instance)
      model_instance.photo.attached?
    end

    # Remove photo attachment
    def remove_photo(model_instance)
      return { success: false, error: 'No photo to remove' } unless model_instance.photo.attached?

      begin
        model_instance.photo.purge
        { success: true, message: 'Photo removed successfully' }
      rescue => e
        Rails.logger.error("Photo removal failed: #{e.message}")
        { success: false, error: 'Failed to remove photo. Please try again.' }
      end
    end

    private

    # Validate image file type
    def valid_image?(file)
      return false unless file.respond_to?(:content_type)
      
      allowed_types = %w[image/jpeg image/jpg image/png image/gif image/webp]
      allowed_types.include?(file.content_type.downcase)
    end

    # Validate file size (max 5MB)
    def valid_size?(file)
      return false unless file.respond_to?(:size)
      
      max_size = 5.megabytes
      file.size <= max_size
    end
  end
end 