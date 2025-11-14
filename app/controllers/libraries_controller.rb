class LibrariesController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_member!, only: %i[ show ]
  before_action :required_subscription

  def show
    @months = (1..12).map { |month| month.to_s.rjust(2, "0") }

    @years = current_user.subscriptions.map do |subscription|
      (subscription.start_date..subscription.end_date).map { |day| day.strftime("%Y") }
    end.flatten.uniq.sort

    conditions = current_user.subscriptions.map do |subscription|
      "(published_at >= '#{subscription.start_date}' and published_at <= '#{subscription.end_date}')"
    end

    scope = Newspaper.where(conditions.join(" OR ")).filter_by_month(params[:month], params[:year]).order_by_published_date.distinct

    per_page = params[:per_page].presence || 8

    @pagy, @newspapers = pagy(scope, limit: per_page, page: params[:page])
  end

  def required_subscription
    redirect_to root_path, alert: t("alerts.messages.require_subscription") if current_user.subscriptions.blank?
  end
end
