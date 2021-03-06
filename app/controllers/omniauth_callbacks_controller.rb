class OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def stripe_connect
    @market = Market.find_by_subdomain(params[:state])
    @market.stripe_account_id = request.env["omniauth.auth"]["extra"]["extra_info"]["id"]
    @market.save

    server_name = request.server_name.sub 'app.', "#{params[:state]}."
    redirect_to "#{request.protocol}#{server_name}:#{request.port}/admin/markets/#{@market.id}/stripe", notice: "Account Connected to Stripe"
  end
end