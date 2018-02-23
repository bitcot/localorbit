class DeleteLocations
  include Interactor

  def perform
    organization = context[:organization]
    location_ids = context[:location_ids]

    context[:locations] = organization.locations.where(id: location_ids).each { |loc| loc.soft_delete }
  end
end
