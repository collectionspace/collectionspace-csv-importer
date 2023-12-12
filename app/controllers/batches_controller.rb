# frozen_string_literal: true

class BatchesController < ApplicationController
  before_action :set_tabs, only: %i[index]
  before_action :set_batch, only: %i[destroy]
  before_action :set_group, only: %i[create]

  def index
    @user_only = session.fetch(:user_only, false)
    email = @user_only ? current_user.email : '%'
    @pagy, @batches = pagy(
      policy_scope(Batch).send(session[:tab]).by_user(email).order('created_at DESC')
    )
  end

  def new
    authorize(Batch)
    @batch = Batch.new
    @connection ||= current_user.default_connection
  end

  def create
    respond_to do |format|
      @batch = Batch.new
      if user_and_group_ok?
        check_connection_and_csv(format)
      else
        reset_form(format)
      end
    end
  end

  def destroy
    @batch.destroy
    respond_to do |format|
      format.html do
        redirect_to batches_path, notice: t('action.deleted', record: 'Batch')
      end
    end
  end

  private

  def user_and_group_ok?
    @batch.update(
      permitted_attributes(@batch).merge(user: current_user, group: @group)
    )
  end

  def reset_form(format)
    @connection ||= current_user.default_connection
    format.html { render :new }
  end

  def redirect_to_new_form(format)
    format.html { redirect_to new_batch_path }
  end

  def check_connection_and_csv(format)
    @batch.connection.validate
    csv_validator = Batch.csv_validator_for(@batch)

    if connection_valid? && csv_valid?(csv_validator)
      @batch.update(num_rows: csv_validator.row_count)
      format.html { redirect_to new_batch_step_preprocess_path(@batch) }
    elsif @batch.connection.invalid?
      handle_bad_connection(format)
    else
      handle_bad_csv(format, csv_validator)
    end
  end

  def connection_valid?
    @batch.connection.valid?
  end

  def csv_valid?(validator)
    validator.valid? && within_csv_row_limit?(validator.row_count)
  end

  def handle_bad_connection(format)
    connection_name = @batch.connection.name
    @batch.destroy
    flash[:invalid_connection] = "The `#{connection_name}` connection cannot "\
                                 'connect to CollectionSpace. Please check '\
                                 "the connection's URL and login credentials."
    redirect_to_new_form(format)
  end

  def handle_bad_csv(format, validator)
    if within_csv_row_limit?(validator.row_count)
      @batch.destroy
      flash[:csv_lint] = validator.errors
                                  .map { |err| format_csv_validation_error(err) }
                                  .join('|||')
    else
      @batch.destroy
      flash[:csv_too_long] = true
    end
    redirect_to_new_form(format)
  end

  def format_csv_validation_error(error)
    loc = if error.column
            "Row #{error.row}, column #{error.column}"
          else
            "Row #{error.row}"
          end
    "#{loc}: #{error.category.capitalize} error: #{error.type}"
  end

  def set_batch
    @batch = authorize Batch.find(params[:id])
  end

  def set_group
    @group = if permitted_attributes(Batch).dig(:group_id)
               Group.find(params[:batch][:group_id])
             else
               current_user.group
             end
  end

  def set_tabs
    @tabs = tabs
    current_tab = params.permit(:tab).fetch(:tab, session.fetch(:tab, :working)).to_sym
    raise Pundit::NotAuthorizedError unless @tabs.key? current_tab

    session[:tab] = current_tab
    @tabs[current_tab][:active] = true
  end

  def tabs
    {
      working: { active: false, icon: 'folder', title: t('tabs.batch.working') },
      preprocesses: { active: false, icon: 'step-forward',
                      title: t('tabs.batch.preprocessing') },
      processes: { active: false, icon: 'fast-forward',
                   title: t('tabs.batch.processing') },
      transfers: { active: false, icon: 'share', title: t('tabs.batch.transferring') },
      archived: { active: false, icon: 'archive', title: t('tabs.batch.archived') }
    }
  end
end
