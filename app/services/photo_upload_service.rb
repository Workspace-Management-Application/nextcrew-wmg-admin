class PhotoUploadService
  class << self
    # Attach photo to a model instance using Active Storage with folder organization
    # Usage: PhotoUploadService.attach_photo(workspace, params[:photo], 'workspaces', 'photo')
    def attach_photo(model_instance, photo_file, folder = nil, attachment_type = 'photo')
      return { success: false, error: 'No photo provided' } if photo_file.blank?
      return { success: false, error: 'Invalid file type' } unless valid_image?(photo_file)
      return { success: false, error: 'File too large' } unless valid_size?(photo_file)

      begin
        # Generate organized filename with folder structure
        organized_filename = generate_organized_filename(photo_file, folder, model_instance, attachment_type)
        
        # Attach with custom filename for S3 organization
        attachment = model_instance.send(attachment_type)
        attachment.attach(
          io: photo_file.tempfile,
          filename: organized_filename,
          content_type: photo_file.content_type
        )
        
        { success: true, message: 'Photo uploaded successfully' }
      rescue => e
        Rails.logger.error("Photo upload failed: #{e.message}")
        { success: false, error: 'Upload failed. Please try again.' }
      end
    end

    # Get photo URL (works in both development and production)
    def photo_url(model_instance, attachment_type = 'photo')
      attachment = model_instance.send(attachment_type)
      return nil unless attachment.attached?

      if Rails.env.development?
        Rails.application.routes.url_helpers.rails_blob_url(attachment, host: 'localhost:3000')
      else
        attachment.url
      end
    end

    # Check if model has photo attached
    def photo_attached?(model_instance, attachment_type = 'photo')
      attachment = model_instance.send(attachment_type)
      attachment.attached?
    end

    # Remove photo attachment
    def remove_photo(model_instance, attachment_type = 'photo')
      attachment = model_instance.send(attachment_type)
      return { success: false, error: 'No photo to remove' } unless attachment.attached?

      begin
        attachment.purge
        { success: true, message: 'Photo removed successfully' }
      rescue => e
        Rails.logger.error("Photo removal failed: #{e.message}")
        { success: false, error: 'Failed to remove photo. Please try again.' }
      end
    end

    # Convenience method to auto-detect folder based on model type
    def attach_photo_auto(model_instance, photo_file, attachment_type = 'photo')
      folder = detect_folder_from_model(model_instance)
      attach_photo(model_instance, photo_file, folder, attachment_type)
    end

    private

    # Generate organized filename with folder structure for S3
    def generate_organized_filename(photo_file, folder, model_instance, attachment_type = 'photo')
      folder ||= detect_folder_from_model(model_instance)
      timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
      unique_id = SecureRandom.hex(8)
      file_extension = File.extname(photo_file.original_filename)
      
      "uploads/#{folder}/#{attachment_type}/#{timestamp}_#{unique_id}#{file_extension}"
    end

    # Auto-detect folder name based on model class
    def detect_folder_from_model(model_instance)
      case model_instance.class.name
      when 'Workspace'
        'workspaces'
      when 'Room'
        'rooms'
      when 'DayPass'
        'day_passes'
      when 'VisitorEntry'
        'visitor_entries'
      else
        'general'
      end
    end

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