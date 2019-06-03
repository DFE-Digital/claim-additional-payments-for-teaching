module ApplicationHelper
  def page_title(title)
    content_for :page_title, title
  end

  def claim_in_progress?
    session.key?(:tslr_claim_id)
  end
end
