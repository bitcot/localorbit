module Admin
  class LocationsController < AdminController
    before_action :find_organization

    def index
      @locations = @organization.locations.visible.alphabetical_by_name.decorate
    end

    def new
      @location = @organization.locations.build
    end

    def create
      @location = @organization.locations.build(location_params)

      if @location.save
        redirect_to [:admin, @organization, :locations], notice: "Successfully added address #{@location.name}"
      else
        flash.now[:alert] = "Could not save address"
        render :new
      end
    end

    def edit
      @location = @organization.locations.find(params[:id])
    end

    def update
      @location = @organization.locations.find(params[:id])

      if @location.update_attributes(location_params)
        redirect_to [:admin, @organization, :locations], notice: "Successfully updated address #{@location.name}"
      else
        flash.now[:alert] = "Could not update address"
        render :new
      end
    end

    def update_default
      @organization.locations.update_all(default_billing: false, default_shipping: false)
      @organization.locations.find(params[:default_billing_id]).update_attributes(default_billing: true) if params[:default_billing_id]
      @organization.locations.find(params[:default_shipping_id]).update_attributes(default_shipping: true) if params[:default_shipping_id]

      redirect_to [:admin, @organization, :locations], notice: "Successfully updated default addresses"
    end

    def destroy
      loc_ids = *params[:location_ids]
      result = DeleteLocations.perform(organization: @organization, location_ids: loc_ids)
      @locations = result.locations
      redirect_to [:admin, @organization, :locations], notice: "Successfully removed the address(es) #{location_names}"
    end

    private

    def find_organization
      # KXM GC: Locations#find_organization will need refinement
      # specifically related to returning the current_market parent organization (here reflected by current_user.managed_markets.first.organization)
      @organization = current_user.managed_organizations.find_by_id(params[:organization_id]) || current_user.managed_markets.first.organization
    end

    def location_params
      params.require(:location).permit(:name, :address, :city, :state, :zip, :country, :phone, :fax, :email, :contact_name, :default_billing)
    end

    def location_names
      @locations.map(&:name).to_sentence
    end
  end
end
