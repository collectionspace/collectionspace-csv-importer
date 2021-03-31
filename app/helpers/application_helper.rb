# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def admin?
    current_user.admin?
  end

  def allowed_access?
    current_user.enabled? && !non_admin_default_group_user?
  end

  def can_affiliate?(user)
    return false if current_user.is?(user)
    return false if user.admin?
    return true if current_user.manage?(user)
  end

  def can_edit_connection_profile?(connection)
    return false if connection.new_record? && current_user.group.profile?
    return false if connection.group&.profile?

    true
  end

  def can_edit_user_group?(user)
    # a user can update their affiliation
    return true if current_user.is?(user) && !user.admin?

    current_user.admin? && !user.admin?
  end

  def can_toggle_status?(record)
    if record.respond_to?(:role)
      return false if record.superuser?
      return false if current_user.is?(record)
    end

    manage?(record)
  end

  def connections_for_batch
    current_user.connections.where(group: current_user.group)
  end

  def csv_content_types
    Batch.content_types.join(',')
  end

  def current_step_path(batch)
    step_state = batch.aasm(:step).human_state.to_sym
    step_state = :preprocess if step_state == :new
    send("new_batch_step_#{step_state}_path", batch)
  end

  def current_step_cancel_path(batch, step)
    step_state = batch.aasm(:step).human_state.to_sym
    if batch.can_cancel?
      send("batch_step_#{step_state}_cancel_path", batch, step)
    else
      '#'
    end
  end

  def current_step_reset_path(batch, step)
    step_state = batch.aasm(:step).human_state.to_sym
    if batch.can_reset?
      send("batch_step_#{step_state}_reset_path", batch, step)
    else
      '#'
    end
  end

  def filename_js
    filename_target = 'document.getElementById("file-name").textContent'
    filename_value = 'document.getElementById("batch_spreadsheet").value'
    filename_transform = 'replace("C:\\\\fakepath\\\\", "")'
    "#{filename_target} = #{filename_value}.#{filename_transform}"
  end

  def impersonating_user?
    current_user != true_user
  end

  def manage?(record)
    current_user.manage?(record)
  end

  def non_admin_default_group_user?
    current_user.group?(Group.default) && !current_user.admin?
  end

  def spinner_html
    "<i class='fa fa-spinner fa-spin'></i>"
  end

  def spinner_js
    'this.querySelector(".fa-refresh").classList.add("fa-spin");'
  end

  def status_color(status)
    case status
    when :ready
      'primary'
    when :pending
      'info'
    when :running
      'success'
    when :cancelled
      'warning'
    when :finished
      'success'
    when :failed
      'danger'
    end
  end

  def status_icon(status)
    case status
    when :ready
      'plus'
    when :pending
      'pause'
    when :running
      'refresh spin'
    when :cancelled
      'exclamation-circle'
    when :finished
      'thumbs-up'
    when :failed
      'exclamation-triangle'
    end
  end

  # when impersonating a user don't allow the impersonator
  # to escape their assigned groups
  def switchable_groups(groups)
    return groups unless impersonating_user?

    groups & true_user.groups
  end

  def unassigned_message
    if non_admin_default_group_user?
      raw t('user.unauthorized_group', email: Group.default.email)
    elsif current_user.group.disabled?
      raw t('user.unassigned_group')
    elsif current_user.group.email
      raw t('user.unassigned_user', email: current_user.group.email)
    else
      t('user.unassigned')
    end
  end

  def waiting_to_start_html
    '<span class="is-italic">not started</span>'
  end
end
