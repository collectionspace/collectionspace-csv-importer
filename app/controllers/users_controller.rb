# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :set_user, only: %i[edit update update_group destroy]
  before_action :set_connections, only: %i[edit update]
  before_action :check_for_illegal_promote_to_admin, only: %i[update]

  def index
    authorize(User)
    @pagy, @users = pagy(
      policy_scope(User).includes(:group, :role).order('groups.name asc, users.email asc')
    )
  end

  def edit; end

  def update
    respond_to do |format|
      scrub_params(:user, :password)
      scrub_params(:user, :password_confirmation)
      affiliate_user_with_group

      if !params[:user].blank? && @user.update(user_params)
        reset_user(@user)
        format.html do
          redirect_to edit_user_path(@user),
                      notice: t('action.updated', record: 'User')
        end
      else
        format.html { render :edit }
      end
    end
  end

  def update_group
    respond_to do |format|
      if @user.group.update(user_group_params)
        format.html do
          redirect_to edit_user_path(@user), notice: t('user.group_updated')
        end
      else
        format.html do
          redirect_to edit_user_path(@user), alert: error_messages(@user.group.errors)
        end
      end
    end
  end

  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: t('action.deleted', record: 'User') }
    end
  end

  # Become user functionality
  def impersonate
    user = authorize User.find(params[:id])
    impersonate_user(user)
    redirect_back fallback_location: root_path
  end

  def stop_impersonating
    stop_impersonating_user
    redirect_to root_path
  end

  private

  def affiliate_user_with_group
    if current_user.admin? && !@user.admin?
      group_id = params.dig(:user, :group_id) || params[:group_id]
      @user.groups << Group.find(group_id) if group_id
    end
  end

  def check_for_illegal_promote_to_admin
    role_id = params.dig(:user, :role_id) || params[:role_id]
    if !current_user.admin? && role_id && Role.find(role_id).name == Role::TYPE[:admin]
      raise Pundit::NotAuthorizedError
    end
  end

  def reset_user(user)
    current_user.is?(user) ? bypass_sign_in(user) : bypass_sign_in(current_user)
  end

  def set_connections
    @connections = @user.connections.where(group: @user.group)
  end

  def set_user
    @user = authorize User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(policy(@user).permitted_attributes)
  end

  def user_group_params
    params.require(:group).permit(:name, :email, :profile)
  end
end
