module Financials
  module OrderItemFeeCalculator
    class << self

      def market_fee_paid_by_seller(market:, order_item:)
        if market.nil? and !order_item.nil?
          market = order_item.order.market
        end # see below
        rate = market.market_seller_fee / 100
        return round(rate * (order_item.gross_total - order_item.discount_seller))
      end
      
      def local_orbit_fee_paid_by_seller(market:, order_item:)
        if market.nil? and !order_item.nil?
          market = order_item.order.market
        end # add to take care of calling this separately on an order item -- is this a problem? jzc 2016-02-18
        rate = market.local_orbit_seller_fee / 100
        # TODO: IS THIS RIGHT?  Really discount the gross total by both seller and market share of the discount? This was how it was originally in StoreOrderFees.  crosby 2015-06-02
        return round(rate * (order_item.gross_total - order_item.discount_market - order_item.discount_seller))

      end

      def local_orbit_fee_paid_by_market(market:, order_item:)
        if market.nil? and !order_item.nil?
          market = order_item.order.market
        end # see above
        rate = market.local_orbit_market_fee / 100
        # TODO: IS THIS RIGHT?  Really discount the gross total by both seller and market share of the discount? This was how it was originally in StoreOrderFees.  crosby 2015-06-02
        return round(rate * (order_item.gross_total - order_item.discount_market - order_item.discount_seller))
      end

      private
      def round(dec)
        dec.round(2)
      end
    end
  end
end

