class ApplicationMailer < ActionMailer::Base
  default from: -> { Company.first&.email || "noreply@dailynews.com" }
  layout "mailer"
end
