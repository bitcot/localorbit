module PaymentProvider
  class Stripe
    CreditCardFeeStructure = SchemaValidation.validate!(FeeEstimator::Schema::BasePlusRate,
      style: :base_plus_rate,
      base:  30,
      rate:  "0.029".to_d, # 2.9% of total
    )

    class << self
      def id; :stripe; end

      def supported_payment_methods
        [ "credit card" ]
      end

      def place_order(buyer_organization:, user:, order_params:, cart:)
        PlaceStripeOrder.perform(payment_provider: :stripe, 
                                 entity: buyer_organization, 
                                 buyer: user,
                                 order_params: order_params, 
                                 cart: cart)
      end

      def translate_status(charge:, cart:nil, payment_method:nil)
        return 'failed' if charge.nil?
        case charge.status
        when 'pending'   then 'pending'
        when 'succeeded' then 'paid'
        else
          'failed'
        end
      end

      def charge_for_order(amount:, bank_account:, market:, order:, buyer_organization:)
        amount_in_cents = ::Financials::MoneyHelpers.amount_to_cents(amount)
        customer = buyer_organization.stripe_customer_id
        source = bank_account.stripe_id
        destination = market.stripe_account_id
        descriptor = market.on_statement_as
        
        fee_in_cents = PaymentProvider::FeeEstimator.estimate_payment_fee CreditCardFeeStructure, amount_in_cents

        # TODO: once we support ACH via Stripe, this branch will be needed for an alternate estimate of ACH fees:
        # fee_in_cents = if bank_account.credit_card?
        #                  estimate_credit_card_processing_fee_in_cents(amount_in_cents)
        #                else
        #                  estimate_ach_processing_fee_in_cents(amount_in_cents)
        #                end
        
        return ::Stripe::Charge.create(
          amount: amount_in_cents, 
          currency: 'usd', 
          source: source, 
          customer: customer,
          destination: destination, 
          statement_descriptor: descriptor,
          application_fee: fee_in_cents)
      end

      def fully_refund(charge:nil, payment:, order:)
        raise "fully_refund not implemented for Stripe provider yet"
      end

    end
    
  end
end
