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
      if @batch.update(
        permitted_attributes(@batch).merge(user: current_user, group: @group)
      )
        if spreadsheet_ok?
          format.html do
            redirect_to new_batch_step_preprocess_path(@batch)
          end
        else
          format.html { return redirect_to new_batch_path }
        end
      else
        @connection ||= current_user.default_connection
        format.html do
          render :new
        end
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

  def format_csv_validation_error(error)
    loc = if error.column
            "Row #{error.row}, column #{error.column}"
          else
            "Row #{error.row}"
          end
    "#{loc}: #{error.category.capitalize} error: #{error.type}"
  end

  def spreadsheet_ok?
    continue = false
    Batch.csv_validator_for(@batch) do |validator|
      if validator.valid? && within_csv_row_limit?(validator.row_count)
        @batch.update(num_rows: validator.row_count)
        continue = true
      elsif !within_csv_row_limit?(validator.row_count)
        @batch.destroy # scrap it, they'll have to start over
        flash[:csv_too_long] = true
      else
        @batch.destroy # scrap it, they'll have to start over
        flash[:csv_lint] = validator.errors
          .map{ |err| format_csv_validation_error(err) }
          .join('|||')
      end
    end

    continue
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
