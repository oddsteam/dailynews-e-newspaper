class OrderMailer < ApplicationMailer
  default from: Rails.application.credentials.dig(:smtp, :from)

  def receipt_email(order)
    @order = order
    @subscription = order.subscription
    @product = order.product
    @user = order.member

    # Generate PDF receipt
    pdf = Receipts::SimplifiedReceiptPdf.new(order)

    # Attach PDF to email
    attachments["receipt-#{order.receipt_number}.pdf"] = pdf.render

    mail(
      to: @user.email,
      subject: "ใบเสร็จรับเงิน - #{@product.title}"
    )
  end
end
