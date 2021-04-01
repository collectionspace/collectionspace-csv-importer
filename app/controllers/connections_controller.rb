# frozen_string_literal: true

class ConnectionsController < ApplicationController
  before_action :set_connection, only: %i[edit update destroy]
  before_action :check_for_connection_targets_another_user, only: %i[new create]

  def new
    @connection = Connection.new
  end

  def edit; end

  def create
    respond_to do |format|
      @connection = Connection.new
      if @connection.update(permitted_attributes(@connection))
        format.html do
          redirect_to edit_user_path(current_user)
        end
      else
        format.html do
          flash.now[:alert] = error_messages(@connection.errors)
          render :new
        end
      end
    end
  end

  def update
    respond_to do |format|
      scrub_params(:connection, :password)
      if @connection.update(permitted_attributes(@connection))
        format.html do
          redirect_to edit_connection_path(@connection),
                      notice: t(notice_for_domain('updated'), record: 'Connection')
        end
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    user = @connection.user
    @connection.destroy
    respond_to do |format|
      format.html do
        redirect_to edit_user_path(user),
                    notice: t('action.deleted', record: 'Connection')
      end
    end
  end

  private

  def check_for_connection_targets_another_user
    user_id = params.dig(:connection, :user_id) || params[:user_id]
    if user_id.blank? || user_id.to_i != current_user.id
      raise Pundit::NotAuthorizedError
    end
  end

  def notice_for_domain(action)
    @connection.domain ? "action.#{action}" : "action.#{action}_disabled"
  end

  def set_connection
    @connection = authorize Connection.find(params[:id])
  end
end
