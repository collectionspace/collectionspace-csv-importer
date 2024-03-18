# frozen_string_literal: true

class ApplicationReflex < StimulusReflex::Reflex
  # Learn more at: https://docs.stimulusreflex.com
  delegate :current_user, to: :connection

  # add a slight delay to page reload
  def reload
    sleep 0.5
  end

  def toggle_affiliation
    group = Affiliation.find(element.dataset['affiliation-id']).group
    user = User.find(element.dataset['user-id'])
    return unless group && user
    return if user.admin? # don't mess with an admins affiliations (not in UI)
    return if user.group == group # cannot switch out the current group

    if element[:checked]
      user.groups << group
    else
      user.groups.delete group
    end
  end

  def toggle_checkbox
    value = element.dataset['value'].to_sym
    session[value] = element[:checked]
  end

  def toggle_hide
    hide = element.dataset['value'].to_sym
    session[hide] ||= false # make sure there's a default (not hidden)
    session[hide] = !session[hide]
  end
end
