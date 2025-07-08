class Admin::AmenitiesController < Admin::BaseController
  def index
    @amenities = Amenity.order(:name)
    @amenity = Amenity.new
    if request.post? && params[:amenity].present?
      @amenity.assign_attributes(amenity_params)
      if @amenity.save
        redirect_to admin_amenities_path, notice: 'Amenity was successfully created.'
      else
        render :index
      end
    end
  end

  def create
    @amenity = Amenity.new(amenity_params)
    if @amenity.save
      redirect_to admin_amenities_path, notice: 'Amenity was successfully created.'
    else
      @amenities = Amenity.order(:name)
      render :index
    end
  end

  def destroy
    @amenity = Amenity.find(params[:id])
    if Amenity::DEFAULT_TYPES.include?(@amenity.name)
      redirect_to admin_amenities_path, alert: 'Default amenities cannot be deleted.'
    else
      @amenity.destroy
      redirect_to admin_amenities_path, notice: 'Amenity was successfully deleted.'
    end
  end

  private

  def amenity_params
    params.require(:amenity).permit(:name)
  end
end
