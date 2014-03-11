class Admin::BankAccountsController < AdminController
  before_filter :check_user_authorized_to_manage_organization

  def index
    @bank_accounts = @organization.bank_accounts
  end

  def new
    @bank_account = @organization.bank_accounts.build
  end

  def create
    results = AddBankAccountToOrganization.perform(organization: @organization, bank_account_params: bank_account_params)

    if results.success?
      redirect_to admin_organization_bank_accounts_path(@organization)
    else
      @bank_account = results.bank_account
      render :new
    end
  end

  private

  def check_user_authorized_to_manage_organization
    @organization = Organization.find(params[:organization_id])

    head :unauthorized unless current_user.can_manage_organization?(@organization)
  end

  def bank_account_params
    params.require(:bank_account).permit(
      :bank_name,
      :last_four,
      :balanced_uri,
      :account_type
    )
  end
end

