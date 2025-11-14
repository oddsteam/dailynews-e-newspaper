class Newspaper < ApplicationRecord
  has_one_attached :pdf
  has_one_attached :cover

  scope :order_by_published_date, -> { order(published_at: :desc) }

  scope :filter_by_month, ->(month, year) {
    return all if month.blank? && year.blank?

    if year.present? && month.blank?
      start_date = Time.zone.local(year.to_i, 1, 1)
      end_date   = start_date.end_of_year.end_of_day
      return where(published_at: start_date..end_date)
    end

    if month.present? && year.blank?
      return where("EXTRACT(MONTH FROM published_at) = ?", month.to_i)
    end

    if month.present? && year.present?
      start_date = Time.zone.local(year.to_i, month.to_i, 1)
      end_date   = start_date.end_of_month.end_of_day
      return where(published_at: start_date..end_date)
    end

    all
  }

  scope :search, ->(query) {
    if query.present?
      term = "%#{query}%"
      where(
        "title ILIKE :term OR description ILIKE :term OR " \
        "to_char(published_at, 'DD Mon') ILIKE :term OR " \
        "to_char(published_at, 'Mon DD') ILIKE :term OR " \
        "to_char(published_at, 'DD/MM') ILIKE :term OR " \
        "to_char(published_at, 'Month DD, YYYY') ILIKE :term",
        term: term
      )
    else
      all
    end
  }
end
