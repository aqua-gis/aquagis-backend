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
  end

  private

  ##
  # handle password authentication
  def password_authentication(username, password)
    cookies.permanent[:keycloak_token] = Keycloak::Client.get_token(username, password)
    logger.info("--->auth by database")
    if (user = User.authenticate(:username => username, :password => password))
       successful_login(user)
    elsif(Keycloak::Client.user_signed_in?)
      @user = JSON.parse Keycloak::Client.get_userinfo
      user = User.new(
        :email => username,
        :status => "active",
        :pass_crypt => Digest::MD5.hexdigest(password),
        :display_name => @user['name'],
        :data_public => 1,
        :description => "desc"
      )
      user.save!;
      successful_login(user);
     #elsif User.authenticate(:username => username, :password => password, :suspended => true)
     #  failed_login t("sessions.new.account is suspended", :webmaster => "mailto:#{Settings.support_email}").html_safe, username
     else
       failed_login t("sessions.new.auth failure"), username
     end
  end
end
