require 'spec_helper'

describe Market do
  describe 'validates' do
    let!(:original_market) { create(:market) }

    it 'name is unique' do
      market = build(:market)
      market.name = original_market.name

      expect(market).to_not be_valid
      expect(market).to have(1).error_on(:name)
    end

    it 'subdomain is unique' do
      market = build(:market)
      market.subdomain = original_market.subdomain

      expect(market).to_not be_valid
      expect(market).to have(1).error_on(:subdomain)
    end
  end

  describe 'before_save' do
    let(:market) { build(:market) }

    it 'remove @ from twitter slug' do
      market.twitter = '@collectiveidea'

      expect(market.save!).to be true
      market.reload
      expect(market.twitter).to eq('collectiveidea')
    end

    it "leaves the twitter slug alone if it doesn't start with @" do
      market.twitter = 'collectiveidea'

      expect(market.save!).to be true
      market.reload
      expect(market.twitter).to eq('collectiveidea')
    end
  end

  describe '#fulfillment_locations' do
    let!(:market) { create(:market) }
    let!(:address1) { create(:market_address, market: market) }
    let!(:address2) { create(:market_address, market: market) }
    let(:default_name) { 'Direct to seller' }
    subject { market.fulfillment_locations(default_name) }

    it 'accepts a parameter as default option name' do
      expect(subject).to include([default_name, 0])
    end

    it 'has market address names' do
      expect(subject).to include([address1.name, address1.id])
      expect(subject).to include([address2.name, address2.id])
    end
  end

  describe "domain" do
    let(:market) { build(:market) }

    it "is is the subdomain with the canonical domain" do
      expect(market.domain).to eq("#{market.subdomain}.#{Figaro.env.domain!}")
    end
  end

  describe "#seller_net_percent" do
    let(:market) { build(:market, local_orbit_seller_fee: "1", local_orbit_market_fee: "2", market_seller_fee: "3", credit_card_seller_fee: "4", credit_card_market_fee: "5", ach_seller_fee: "6", ach_market_fee: "7") }

    it "includes the local_orbit_seller_fee and market_seller_fee" do
      expect(market.seller_net_percent).to eq(BigDecimal.new("0.96"))

      market.local_orbit_seller_fee = "3"
      expect(market.seller_net_percent).to eq(BigDecimal.new("0.94"))

      market.market_seller_fee = "6"
      expect(market.seller_net_percent).to eq(BigDecimal.new("0.91"))
    end
  end
end
