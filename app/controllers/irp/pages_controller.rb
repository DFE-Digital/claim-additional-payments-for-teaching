# frozen_string_literal: true

module Irp
  class PagesController < ApplicationController
    before_action :check_whether_closed_for_submissions, except: %i[closed sitemap]

    def index
    end

    def closed
    end

    def sitemap
    end

    def ineligible
      session.delete("form_id")
    end

    def ineligible_salaried_course
      session.delete("form_id")
    end
  end
end
