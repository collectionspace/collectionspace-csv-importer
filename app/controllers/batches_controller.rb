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
          @batch.destroy
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

  # These tests need to run in order.
  # csv_length_ok? depends on csvlint_ok? passing and setting batch.num_rows
  # Eventually I want to add csv_encoding_ok? prior to running csvlint_ok? to
  #   better handle invalid encoding issues.
  def spreadsheet_ok?
    csvlint_ok? &&
      csv_length_ok? &&
      csv_parse_ok?
  end

  def csvlint_ok?
    Batch.csvlint_validator_for(@batch) do |validator|
      if validator.valid?
        @batch.update(num_rows: validator.row_count)
        true
      else
        flash[:csvlint] = validator.errors
                                   .map { |err| format_csv_validation_error(err) }
                                   .join('|||')
        false
      end
    end
  end

  def csv_length_ok?
    return true if @batch.num_rows <= Rails.configuration.csv_max_rows

    flash[:csv_too_long] = true
    false
  end

  def csv_parse_ok?
    Batch.csv_parse_validator_for(@batch) do |parsed|
      return true if parsed == :success

      # Catches blank rows between data rows or at the end of the CSV
      #   that have mixed EOL characters, which Csvlint does not flag as
      #   invalid, but that raise a malformed CSV error in the CSV library
      #
      # This also catches extraneous CRLF EOL at the end of final data
      #   line, when EOL char used elsewhere in file is CR
      if parsed.start_with?('New line must be')
        flash[:blank_rows] = true
        # Catches extraneous EOL chars at end of final row that do not match
        #   the EOL char used in the rest of the file, which Csvlint calls
        #   calls valid, but that raise a malformed CSV error in the CSV library
      elsif parsed.start_with?('Unquoted fields do not allow new line')
        flash[:last_row_eol] = true
        # Catches any other malformed CSV errors raised by the CSV library, for
        #   files Csvlint called valid
      else
        flash[:malformed_csv] = parsed
      end
    end
    false
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
