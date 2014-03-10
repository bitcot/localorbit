require 'spec_helper'

describe Admin::ProductsController do
  describe "/index" do
    it 'redirects to login if the user is not logged in' do
      get :index

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "/show" do
    let(:user) { create(:user) }
    let(:product1) { create(:product) }
    let(:product2) { create(:product) }

    before do
      user.organizations << product1.organization
      sign_in(user)
    end

    it "does not show a product from another organization" do
      get :show, {id: product2.id}

      expect(response).to be_not_found
    end
  end

  describe "/create" do
    let(:user) { create(:user) }
    let(:org1) { create(:organization) }
    let(:org2) { create(:organization) }

    before do
      org1.users << user
      sign_in(user)
    end

    it 'should not let a user create a product for an organization they do not belong to' do
      post :create, {product: {organization_id: org2, name: "Apple", category_id: 1}}

      expect(response).to render_template("admin/products/new")
      expect(assigns(:product)).to have(1).errors_on(:organization_id)
    end
  end

  describe "/update" do
    let(:user) { create(:user) }
    let(:org1) { create(:organization) }
    let(:product) { create(:product)}

    before do
      org1.users << user
      sign_in(user)
    end

    it 'should not let a user update a product that does not belong to their organization' do
      put :update, {id: product.id, product: {organization_id: org1.id, name: "Apple", category_id: 1}}

      expect(response).to be_not_found
    end
  end

  describe "/new" do
    it "redirects to the add organization page when no selling organizations exist" do
      create(:organization, :buyer)

      admin = create(:user, :admin)
      sign_in admin

      get :new

      expect(response).to redirect_to(new_admin_organization_path)
      expect(flash[:alert]).to eq("You must add an organization that can sell before adding any products")
    end
  end

  describe "destroy" do
    let(:organization)              { create(:organization) }
    let(:product)                   { create(:product, organization: organization) }
    let(:admin)                     { create(:user, :admin) }
    let(:non_member)                { create(:user) }
    let(:market_manager_non_member) { create(:user, :market_manager) }
    let(:member)                    { create(:user, organizations: [organization]) }

    let(:market_manager_member) do
      create(:user, :market_manager).tap do |market_manager|
        market_manager.organizations << organization
      end
    end

    it_behaves_like "an action restricted to admin, market manager, member", lambda { delete :destroy, id: product.id }
  end
end
