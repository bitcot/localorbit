require "spec_helper"

feature "Adding credit card to a market", js: true do
  let!(:admin) { create(:user, :admin) }
  let!(:market_manager) { create(:user, :market_manager) }
  let!(:market) { market_manager.managed_markets.first }
  let!(:org) { create(:organization, markets: [market]) }
  let!(:member) { create(:user, organizations: [org]) }
  let!(:non_member) { create(:user) }

  before do
    CreateBalancedCustomerForEntity.perform(market: market)
  end

  scenario "as an admin" do
    switch_to_subdomain(market.subdomain)
    sign_in_as(admin)

    visit new_admin_market_bank_account_path(market)

    select "Credit Card", from: "balanced_account_type"
    fill_in "Name", with: "John Doe"
    fill_in "Card Number", with: "5105105105105100"
    fill_in "Security Code", with: "123"
    select "5", from: "expiration_month"
    select "2014", from: "expiration_year"

    fill_in "Organization EIN", with: "20-1234567"
    fill_in "Full Legal Name", with: "John Patrick Doe"
    select "Sep", from: "representative_dob_month"
    select "17", from: "representative_dob_day"
    select "1990", from: "representative_dob_year"

    fill_in "Last 4 of SSN", with: "1234"
    fill_in "Street Address (Personal)", with: "6789 Fake Dr"
    fill_in "Zip Code (Personal)", with: "49423"

    click_button "Save"

    expect(page).to have_content("Successfully added a payment method")

    bank_account = Dom::BankAccount.first
    expect(bank_account.bank_name).to eq("MasterCard")
    expect(bank_account.account_number).to eq("**** **** **** 5100")
    expect(bank_account.account_type).to eq("Credit Card")
    expect(bank_account.expiration).to eq("Expires 05/2014")
  end

  scenario "as a market manager" do
    switch_to_subdomain(market.subdomain)
    sign_in_as(market_manager)

    visit new_admin_market_bank_account_path(market)

    select "Credit Card", from: "balanced_account_type"
    fill_in "Name", with: "John Doe"
    fill_in "Card Number", with: "5105105105105100"
    fill_in "Security Code", with: "123"
    select "5", from: "expiration_month"
    select "2014", from: "expiration_year"

    fill_in "Organization EIN", with: "20-1234567"
    fill_in "Full Legal Name", with: "John Patrick Doe"
    select "Sep", from: "representative_dob_month"
    select "17", from: "representative_dob_day"
    select "1990", from: "representative_dob_year"

    fill_in "Last 4 of SSN", with: "1234"
    fill_in "Street Address (Personal)", with: "6789 Fake Dr"
    fill_in "Zip Code (Personal)", with: "49423"

    click_button "Save"

    expect(page).to have_content("Successfully added a payment method")

    bank_account = Dom::BankAccount.first
    expect(bank_account.bank_name).to eq("MasterCard")
    expect(bank_account.account_number).to eq("**** **** **** 5100")
    expect(bank_account.account_type).to eq("Credit Card")
    expect(bank_account.expiration).to eq("Expires 05/2014")
  end

  scenario "as a organization member" do
    switch_to_subdomain(market.subdomain)
    sign_in_as(member)

    visit new_admin_market_bank_account_path(org)

    expect(page).to have_content("The page you were looking for doesn't exist.")
    expect(page.status_code).to eq(404)
  end

  scenario "as a non member" do
    switch_to_subdomain(market.subdomain)
    sign_in_as(non_member)

    visit new_admin_market_bank_account_path(org)

    expect(page).to have_content("The page you were looking for doesn't exist.")
    expect(page.status_code).to eq(404)
  end
end
