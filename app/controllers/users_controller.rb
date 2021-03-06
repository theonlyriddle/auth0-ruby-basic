require 'json'
require 'omniauth/auth0/jwt_validator'

# UsersController - :users resource controller.
class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy correct_user]
  before_action :logged_in, only: %i[index edit update destroy new]
  before_action :correct_user, only: %i[edit update]
  before_action :admin?, only: %i[destroy new]

  # GET /users
  def index
    @users = User.paginate(
      page: params[:page],
      per_page: 20
    ).order('created_at DESC')
  end

  # GET /users/1
  def show
    @id_token = session[:userinfo]['credentials']['id_token']
    if current_user?(@user)
      options = Struct.new(:domain, :client_id, :client_secret)
      auth0_jwt = OmniAuth::Auth0::JWTValidator.new(options.new(
          ENV['AUTH0_RUBY_DOMAIN'],
          ENV['AUTH0_RUBY_CLIENT_ID'],
          ENV['AUTH0_RUBY_CLIENT_SECRET']
      ))
      @id_token = auth0_jwt.decode(@id_token)
    end
    render 'show'
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
    render 'edit'
  end

  # POST /users
  def create
    @user = User.new(user_params)

    if @user.save
      log_in @user
      flash[:success] = 'User created!'
      redirect_to @user
    else
      render 'new'
    end
  end

  # PATCH/PUT /users/1
  def update
    if @user.update_attributes(user_params)
      flash[:success] = 'Updated!'
      redirect_to @user
    else
      render :edit
    end
  end

  # DELETE /users/1
  def destroy
    @user.destroy
    flash[:success] = 'Deleted!'
    redirect_to users_url
  end

  #
  # START - Private methods
  #
  private

  # Require User params, whitelist incoming
  def user_params
    params.require(:user).permit(
      :name,
      :email,
      :password,
      :password_confirmation,
      :auth0_id
    )
  end

  #
  # START - Before filters
  #

  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end

  # Make sure the user is logged in.
  def logged_in
    return if logged_in?
    store_forwarding_loc
    flash[:danger] = 'Login required.'
    redirect_to login_url
  end

  # Make sure we have the correct user.
  def correct_user
    return if current_user_is_admin? || current_user?(@user)
    flash[:danger] = 'Not authorized.'
    redirect_to users_path
  end

  # Make sure we have an admin.
  def admin?
    return if current_user_is_admin?
    flash[:danger] = 'Not authorized.'
    redirect_to users_url
  end

end
