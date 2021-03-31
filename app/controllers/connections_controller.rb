# frozen_string_literal: true

class ConnectionsController < ApplicationController
  before_action :set_connection, only: %i[edit update destroy]

  def new
    @connection = Connection.new
  end

  def edit; end

  def create
    respond_to do |format|
      @connection = Connection.new
      @connection.user = current_user
      @connection.group = current_user.group
      if @connection.update(permitted_attributes(@connection))
        format.html do
          redirect_to edit_user_path(current_user)
        end
      else
        format.html { render :new }
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

  def notice_for_domain(action)
    @connection.domain ? "action.#{action}" : "action.#{action}_disabled"
  end

  def set_connection
    @connection = authorize Connection.find(params[:id])
  end
end
