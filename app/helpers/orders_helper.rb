module OrdersHelper
  def order_number(order, prefix: "DNT")
    return "-" if order.nil?

    date =
      if order.respond_to?(:created_at) && order.created_at.present?
        order.created_at.strftime("%Y%m%d")
      else
        Time.zone.today.strftime("%Y%m%d")
      end

    id_part =
      if order.respond_to?(:id) && order.id.present?
        format("%05d", order.id)
      else
        "00000"
      end

    "#{prefix}-#{date}-#{id_part}"
  end
end
