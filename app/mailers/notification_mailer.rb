class NotificationMailer < ActionMailer::Base
  default from: Houston.config.mailer_sender
  helper UrlHelper
  helper CommitHelper
  helper TicketHelper
  helper MarkdownHelper
  
  
  def on_deploy(release, maintainer)
    @release = release
    
    if release.commits.empty? && release.can_read_commits?
      release.load_commits!
      release.load_tickets!
      release.build_changes_from_commits
    end
    
    @maintainer = maintainer
    @maintainer.reset_authentication_token!
    mail({
      to: format_email_address(maintainer),
      subject: "@#{release.project.slug} new release"
    }) do |format|
      format.html
    end
  end
  
  
  def on_release(release)
    @release = release
    mail({
      from: format_email_address(release.user),
      to: release.notification_recipients.map(&method(:format_email_address)),
      cc: release.maintainers.map(&method(:format_email_address)),
      subject: release_announcement_for(release)
    }) do |format|
      format.html
    end
  end
  
  
  def on_fail_verdict(note)
    @note = note
    @tester = note.user
    @ticket = note.ticket
    mail({
      from: format_email_address(@tester),
      to: @ticket.committers.map { |committer| "#{committer[:name]} <#{committer[:email]}>" },
      cc: @ticket.maintainers.map(&method(:format_email_address)),
      subject: "@#{note.project.slug} [##{@ticket.number}] #{@tester.name} passed judgement #notlookinggood"
    }) do |format|
      format.html
    end
  end
  
  
private
  
  
  def format_email_address(user)
    "#{user.name} <#{user.email}>"
  end
  
  def release_announcement_for(release)
    case release.environment.slug # <-- knowledge of environments
    when "dev"; "Testing updates for #{release.project.name}"
    when "master"; "Release notice for #{release.project.name}"
    end
  end
  
  
end
