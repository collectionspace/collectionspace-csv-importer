# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  include Pagy::Backend
  include Pundit::Authorization
  impersonates :user
  # Pundit dev config:
  # after_action :verify_authorized, except: [:index]
  # after_action :verify_policy_scoped, only: :index

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def within_csv_row_limit?(rows)
    rows < Rails.configuration.csv_max_rows
  end

  def error_messages(errors)
    errors.full_messages.map { |msg| msg }.join('; ')
  end

  def highlight(value)
    value.yield_self { |s| '<span class="highlighted">%s</span>' % s }
  end

  def self.renderer_with_signed_in_user(user)
    ActionController::Renderer::RACK_KEY_TRANSLATION['warden'] ||= 'warden'
    proxy = Warden::Proxy.new({}, Warden::Manager.new({})).tap do |i|
      i.set_user(user, scope: :user, store: false, run_callbacks: false)
    end
    renderer.new('warden' => proxy)
  end

  def scrub_params(type, field)
    params[type].delete(field) if params[type][field].blank?
  end

  private

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    flash[:alert] = t "#{policy_name}.#{exception.query}", scope: 'pundit', default: :default
    redirect_to(request.referrer || root_path)
  end
end
