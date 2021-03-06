class Admin::BankAccountsController < AdminController
  include BankAccountEntity
  before_action :set_payment_provider

  def index
    @bank_accounts = @entity.bank_accounts.visible.chrono
  end

  def new
    @bank_account = @entity.bank_accounts.build
  end

  def create
    results = PaymentProvider.add_payment_method(@payment_provider,
                                                 type: params[:type],
                                                 entity: @entity,
                                                 bank_account_params: bank_account_params,
                                                 representative_params: representative_params)

    if results.success?
      redirect_to [:admin, @entity, :bank_accounts], notice: "Successfully added a payment method"
    else
      alert = results.context[:error] || "Unable to save payment method"
      if results.context[:bank_account].nil?
        # Total bank account creation failure, redirect to #new
        redirect_to({action: :new}, alert: alert)
      else
        # Error adding bank account, re-render #new form w errors:
        flash.now[:alert] = alert
        @bank_account = results.bank_account
        render :new
      end
    end
  end

  def destroy
    @entity.bank_accounts.find(params[:id]).destroy
    redirect_to [:admin, @entity, :bank_accounts], notice: "Successfully removed payment method"
  end

  private

  def bank_account_params
    params.require(:bank_account).permit(
      :bank_name,
      :name,
      :last_four,
      :stripe_tok,
      :account_type,
      :expiration_month,
      :expiration_year,
      :notes
    )
  end

  def representative_params
    return {} if params[:representative].blank?
    params.require(:representative).permit(
      :name,
      :ein,
      {dob: [:year, :month, :day]},
      :ssn_last4,
      {address: [:line1, :postal_code]}
    )
  end

  def set_payment_provider
    @payment_provider = case @entity
                        when Market
                          @entity.payment_provider
                        when Organization
                          # TODO : THIS IS POTENTIALLY CRAZY. Solve for multiple market membership!
                          @entity.markets.first.payment_provider
                        end
  end
end
