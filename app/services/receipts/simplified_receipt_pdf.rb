require "prawn"
require "prawn/table"

module Receipts
  class SimplifiedReceiptPdf
    include Prawn::View

    def initialize(order)
      @order = order
      @company = Company.first
      @subscription = @order.subscription

      font_setup
      content
    end

    def document
      @document ||= Prawn::Document.new(page_size: "A5", margin: 40)
    end

    def font_setup
      font_families.update("thai_receipt" => {
        normal: Rails.root.join("app/assets/fonts/tax_invoice/regular.ttf"),
        italic: Rails.root.join("app/assets/fonts/tax_invoice/regular_italic.ttf"),
        bold: Rails.root.join("app/assets/fonts/tax_invoice/bold.ttf"),
        bold_italic: Rails.root.join("app/assets/fonts/tax_invoice/bold_italic.ttf")
      })
      font "thai_receipt"
      font_size 10
    end

    def content
      logo if @company.logo.attached?
      header
      company_info
      receipt_details
      customer_info
      line_items_section
      subscription_period
      price_summary
      footer_section
    end

    def logo
      if @company.logo.attached?
        logo_path = ActiveStorage::Blob.service.path_for(@company.logo.key)
        image logo_path, width: 60, position: :center
        move_down 10
      end
    end

    def header
      text "ใบเสร็จรับเงิน/ใบกำกับภาษีอย่างย่อ",
           size: 14,
           style: :bold,
           align: :center
      move_down 15
    end

    def company_info
      text @company.name, style: :bold, size: 11
      move_down 3

      address_line = [ @company.address_1, @company.address_2 ].compact.join(" ")
      text address_line
      move_down 2

      text "#{@company.sub_district} #{@company.district}"
      move_down 2

      text "#{@company.province} #{@company.postal_code}"
      move_down 2

      if @company.tax_id.present?
        text "เลขประจำตัวผู้เสียภาษี: #{@company.tax_id}"
        move_down 2
      end

      text "โทร: #{@company.phone_number}"
      move_down 2

      text "อีเมล: #{@company.email}"
      move_down 15
    end

    def receipt_details
      receipt_date = thai_date(@order.paid_at || @order.created_at)

      table([
        [ "เลขที่: #{@order.receipt_number}", "วันที่: #{receipt_date}" ]
      ], width: bounds.width) do |t|
        t.cells.borders = []
        t.cells.padding = [ 0, 0, 5, 0 ]
        t.column(1).align = :right
      end
    end

    def customer_info
      text "อีเมลผู้ซื้อ: #{@order.member.email}"
      move_down 15
    end

    def line_items_section
      text "รายการสินค้า", style: :bold
      move_down 5

      stroke_horizontal_rule
      move_down 10

      product_name = @order.product.title
      quantity = 1  # Subscription orders always have quantity of 1
      unit_price = @order.base_price

      table([
        [ product_name, "x#{quantity}", format_money(unit_price) ]
      ], width: bounds.width, column_widths: [ nil, 40, 80 ]) do |t|
        t.cells.borders = []
        t.column(2).align = :right
      end

      move_down 10
    end

    def subscription_period
      return unless @subscription

      start_date = thai_date(@subscription.start_date)
      end_date = thai_date(@subscription.end_date)

      text "ระยะเวลาสมาชิก: #{start_date} - #{end_date}",
           style: :italic,
           size: 9
      move_down 15
    end

    def price_summary
      base_price = @order.base_price
      tax = @order.tax_amount
      total = @order.total
      item_count = 1  # Subscription orders always have 1 item

      stroke_horizontal_rule
      move_down 10

      summary_data = [
        [ "รวม #{item_count} รายการ", "" ],
        [ "ราคาสินค้า (ยังไม่รวมภาษี)", format_money(base_price) ],
        [ "ภาษีมูลค่าเพิ่ม 7%", format_money(tax) ],
        [ "ยอดรวมสุทธิ", format_money(total) ]
      ]

      table(summary_data, width: bounds.width, position: :right) do |t|
        t.cells.borders = []
        t.cells.padding = [ 2, 0, 2, 0 ]
        t.column(1).align = :right
        t.column(1).width = 100

        # Make total row bold
        t.row(-1).font_style = :bold
        t.row(-1).size = 11
      end

      move_down 15
    end

    def footer_section
      stroke_horizontal_rule
      move_down 10

      text "VAT INCLUDED", align: :center, size: 9, style: :bold
      move_down 5
      text "ขอบคุณที่ใช้บริการ", align: :center, size: 9
    end

    # Helper method to format Thai Buddhist calendar date
    def thai_date(date)
      return "" unless date

      thai_year = date.year + 543
      date.strftime("%d/%m/#{thai_year}")
    end

    # Helper method to format money
    def format_money(money)
      "#{sprintf('%.2f', money.to_f)} บาท"
    end
  end
end
