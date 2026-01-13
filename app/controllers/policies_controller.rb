class PoliciesController < ApplicationController
  ALLOWED_PAGES = %w[terms_of_service privacy cookies].freeze

  def show
    @page = params[:id]

    unless ALLOWED_PAGES.include?(@page)
      raise ActionController::RoutingError, "Policy page not found"
    end

    @content = load_markdown_content(@page)
    render :show
  end

  private

  def load_markdown_content(filename)
    file_path = Rails.root.join("app", "content", "#{filename}.md")
    if File.exist?(file_path)
      File.read(file_path)
    else
      "# #{filename.titleize}\n\nContent coming soon..."
    end
  end
end
