class Order < ActiveRecord::Base

  belongs_to :user
  has_one :transaction, :class_name => "OrderTransaction"
  belongs_to :wish_list
  def express_token=(token)
    self[:express_token] = token
    if new_record? && !token.blank?
      details = EXPRESS_GATEWAY.details_for(token)
      self.express_payer_id = details.payer_id
      self.first_name = details.params["first_name"]
      self.last_name = details.params["last_name"]
      self.amount = details.params["order_total"]
    end
  end

  def confirm
    response = process_purchase

    response.success?
  end

  def purchase
    response = process_purchase
    self.build_transaction
    transaction.create!(:response => response)
  end

  private

  def process_purchase
    EXPRESS_GATEWAY.purchase(self.amount, express_purchase_options)
  end

  def express_purchase_options
    {
      :ip => ip_address,
      :token => express_token,
      :payer_id => express_payer_id
    }
  end

end

