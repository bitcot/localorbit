require "spec_helper"

feature "sending invoices" do
  let(:market1) { create(:market, subdomain: 'betterest', po_payment_term: 14) }
  let!(:market_manager) { create :user, managed_markets: [market1] }
  let!(:delivery_schedule) { create(:delivery_schedule) }
  let!(:delivery)    { delivery_schedule.next_delivery }



  let!(:buyer_user) { create :user }

  let!(:market1_seller1) { create(:organization, :seller, name: "Better Farms", markets: [market1]) }
  let!(:market1_buyer1)  { create(:organization, :buyer, name: "Money Bags", markets: [market1], users: [buyer_user]) }
  let!(:market1_buyer2) { create(:organization, :buyer, name: "Money Satchels", markets: [market1]) }

  let!(:product) { create(:product, :sellable, organization: market1_seller1) }

  let!(:market1_order1) { create(:order, delivery: delivery, items:[create(:order_item, product: product, unit_price: 210.00)], market: market1, organization: market1_buyer1, payment_method: 'purchase order', order_number: "LO-001", total_cost: 210, placed_at: Time.zone.parse("2014-04-01")) }
  let!(:market1_order2) { create(:order, delivery: delivery, items:[create(:order_item, product: product)], market: market1, organization: market1_buyer1, invoiced_at: 1.day.ago, invoice_due_date: 13.days.from_now) }
  let!(:market1_order3) { create(:order, delivery: delivery, items:[create(:order_item, product: product)], market: market1, organization: market1_buyer1, payment_method: 'credit card') }
  let!(:market1_order4) { create(:order, delivery: delivery, items:[create(:order_item, product: product)], market: market1, organization: market1_buyer1, payment_method: 'ach') }
  let!(:market1_order5) { create(:order, delivery: delivery, items:[create(:order_item, product: product, unit_price: 420.00)], market: market1, organization: market1_buyer1, payment_method: 'purchase order', order_number: "LO-005", total_cost: 420, placed_at: Time.zone.parse("2014-04-02")) }
  let!(:market1_order6) { create(:order, delivery: delivery, items:[create(:order_item, product: product, unit_price: 310.00)], market: market1, organization: market1_buyer2, payment_method: 'purchase order', order_number: "LO-006", total_cost: 310, placed_at: Time.zone.parse("2014-04-03")) }

  invoice_auth_matcher = lambda {|r1, r2|
    matcher = %r{/admin/invoices/[0-9]+/invoice\.pdf\?auth_token=}
    matcher.match(r1.uri) && matcher.match(r2.uri)
  }

  before do
    switch_to_subdomain(market1.subdomain)
    sign_in_as market_manager
    visit admin_financials_invoices_path
  end

  scenario "seeing a list of unsent invoices" do
    # Orders paid with PO payment type, that have no invoiced_at time
    invoice_rows = Dom::Admin::Financials::InvoiceRow.all
    expect(invoice_rows.size).to eq(3)

    invoice = invoice_rows.first

    expect(invoice.order_number).to eq("LO-001")
    expect(invoice.buyer).to eq("Money Bags")
    expect(invoice.order_date).to eq("04/01/2014")
    expect(invoice.amount).to eq("$210.00")
    expect(invoice.action).to include("Send Invoice")
    expect(invoice.action).to include("Preview")
  end

  scenario "sending a invoice", vcr: {match_requests_on: [:host, invoice_auth_matcher]} do
    Dom::Admin::Financials::InvoiceRow.first.send_invoice

    expect(page).to have_content("Invoice sent for order number LO-001")
    expect(Dom::Admin::Financials::InvoiceRow.all.size).to eq(2)

    open_email(buyer_user.email)

    expect(current_email).to have_subject("New Invoice")
    expect(current_email).to have_body_text("Invoice")
    expect(current_email).to have_body_text("Reference Number: LO-001")
    expect(current_email.attachments.size).to eq(1)

    attachment = current_email.attachments.first
    expect(attachment.filename).to eq("invoice.pdf")
    expect(attachment.content_type).to eq("application/pdf; charset=UTF-8")
  end

  scenario "sending an invoice to an organization with no users" do
    Dom::Admin::Financials::InvoiceRow.all.last.send_invoice

    expect(page).to have_content("Invoice sent for order number LO-006")
    expect(Dom::Admin::Financials::InvoiceRow.all.size).to eq(2)

    expect(ActionMailer::Base.deliveries.size).to eq(0)
  end

  scenario "sending selected invoices", :js, vcr: {match_requests_on: [:host, invoice_auth_matcher]} do
    Dom::Admin::Financials::InvoiceRow.select_all
    click_button 'Send Selected Invoices'

    expect(page).to have_content("Invoice sent for order numbers LO-001, LO-005, LO-006")
    expect(Dom::Admin::Financials::InvoiceRow.all.size).to eq(0)
  end

  context "filtering" do
    let(:market2) { create(:market, subdomain: 'betterest2', po_payment_term: 14) }
    let!(:market_manager) { create :user, managed_markets: [market1, market2] }
    let!(:buyer_user2) { create :user }
    let!(:market2_seller1) { create(:organization, :seller, name: "Better Farms", markets: [market2]) }
    let!(:market2_buyer1)  { create(:organization, :buyer, name: "Money Bags", markets: [market2], users: [buyer_user2]) }
    let!(:market2_buyer2) { create(:organization, :buyer, name: "Money Satchels", markets: [market2]) }
    let!(:market2_order1) { create(:order, items:[create(:order_item, product: product, unit_price: 210.00)], market: market2, organization: market2_buyer1, payment_method: 'purchase order', order_number: "LO-007", total_cost: 210, placed_at: Time.zone.parse("2014-04-01")) }
    let!(:market2_order2) { create(:order, items:[create(:order_item, product: product)], market: market2, organization: market2_buyer1, invoiced_at: 1.day.ago, invoice_due_date: 13.days.from_now) }
    let!(:market2_order3) { create(:order, items:[create(:order_item, product: product)], market: market2, organization: market2_buyer1, payment_method: 'credit card') }
    let!(:market2_order4) { create(:order, items:[create(:order_item, product: product)], market: market2, organization: market2_buyer1, payment_method: 'ach') }
    let!(:market2_order5) { create(:order, items:[create(:order_item, product: product, unit_price: 420.00)], market: market2, organization: market2_buyer1, payment_method: 'purchase order', order_number: "LO-008", total_cost: 420, placed_at: Time.zone.parse("2014-04-02")) }
    let!(:market2_order6) { create(:order, items:[create(:order_item, product: product, unit_price: 310.00)], market: market2, organization: market2_buyer2, payment_method: 'purchase order', order_number: "LO-009", total_cost: 310, placed_at: Time.zone.parse("2014-04-03")) }
  end
end
