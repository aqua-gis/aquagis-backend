class SessionsController < ApplicationController
  include SessionMethods

  layout "site"

  before_action :disable_terms_redirect, :only => [:destroy]
  before_action :authorize_web
  before_action :set_locale
  before_action :check_database_readable
  before_action :require_cookies, :only => [:new]

  authorize_resource :class => false

  def new
    append_content_security_policy_directives(
      :form_action => %w[*]
    )

    session[:referer] = safe_referer(params[:referer]) if params[:referer]
  end

  def create
    session[:remember_me] ||= params[:remember_me]
    session[:referer] = safe_referer(params[:referer]) if params[:referer]
    password_authentication(params[:username], params[:password])
  end

  def destroy
    flash[:success] = 'See you later' if Keycloak::Client.logout
    redirect_to root_path
    @title = t "sessions.destroy.title"
2   
  end

  private

  ##
  # handle password authentication
  def password_authentication(username, password)
    cookies.permanent[:keycloak_token] = Keycloak::Client.get_token(username, password)
    successful_login(User.new()) if Keycloak::Client.user_signed_in?
  end
end
