module Admin
  module Financials
    class ReceiptsController < AdminController
      include StickyFilters

      before_action :find_sticky_params, only: :index

      def index
        if params["clear"]
          redirect_to url_for(params.except(:clear))
        else
          @search_presenter = OrderSearchPresenter.new(@query_params, current_user, :placed_at)

          @q = for_receipts.order("orders.invoice_due_date").search(@search_presenter.query)
          @q.sorts = ["invoice_due_date"] if @q.sorts.empty?
          @orders = @q.result.page(params[:page]).per(@query_params[:per_page])
        end
      end

      def edit
        @order   = for_receipts.find(params[:id])
        @payment = @order.payments.build
      end

      def update
        @buyer_payment = RecordBuyerPayment.perform(order: for_receipts.find(params[:id]), payment_params: payment_params)
        if @buyer_payment.success?
          redirect_to admin_financials_receipts_path, notice: "Payment recorded for order #{@buyer_payment.order.order_number}"
        else
          @order   = @buyer_payment.order
          @payment = @buyer_payment.payment
          render :edit
        end
      end

      protected

      def for_receipts
        Order.orders_for_seller(current_user).invoiced.unpaid
      end

      def payment_params
        params.require(:payment).permit(:payment_method, :amount, :note)
      end
    end
  end
end
