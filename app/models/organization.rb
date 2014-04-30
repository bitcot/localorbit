class Organization < ActiveRecord::Base
  has_many :market_organizations
  has_many :user_organizations

  has_many :users, through: :user_organizations
  has_many :markets, through: :market_organizations
  has_many :orders, inverse_of: :organization

  has_many :products, inverse_of: :organization, autosave: true
  has_many :carts

  has_many :locations, inverse_of: :organization

  has_many :bank_accounts, as: :bankable

  validates :name, presence: true, length: {maximum: 255, allow_blank: true}

  scope :selling, -> { where(can_sell: true) }
  scope :buying,  -> { where(can_sell: false) } # needs a new boolean
  scope :visible, -> { where(show_profile: true) }
  scope :with_products, -> { joins(:products).select("DISTINCT organizations.*").order(name: :asc) }

  serialize :twitter, TwitterUser

  accepts_nested_attributes_for :locations

  dragonfly_accessor :photo

  scope_accessible :market, method: :for_market_id, ignore_blank: true

  def self.for_market_id(market_id)
    orgs = !all.to_sql.include?('market_organizations') ? joins(:market_organizations) : all
    orgs.where(market_organizations: { market_id: [market_id] })
  end

  def shipping_location
    locations.visible.default_shipping
  end

  def billing_location
    locations.visible.default_billing
  end
end
