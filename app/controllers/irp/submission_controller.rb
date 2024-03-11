module Irp
  class SubmissionController < ApplicationController
    before_action :check_whether_closed_for_submissions
    before_action :redirect_to_root_path_when_no_form, only: %i[summary create]

    def summary
      @summary = Summary.new(current_form)
    end

    def show
      @urn = Claim.find_by_id(session[:claim_id])&.reference
      if @urn
        render(:show)
      else
        redirect_to(irp_summary_path)
      end
    end

    def create
      service = SubmitForm.call(current_form, request.remote_ip)
      if service.success?
        update_session(service)
        redirect_to(irp_submission_path)
      else
        @summary = Summary.new(service.form)
        render(:summary)
      end
    end

    private

    def update_session(service)
      # Session :claim_id is used as a standard in claim.
      session[:claim_id] = service.claim.id
      session.delete("form_id")
    end

    def redirect_to_root_path_when_no_form
      redirect_to(root_path) unless current_form
    end
  end
end
