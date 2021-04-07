# frozen_string_literal: true

ActionView::Base.field_error_proc = proc { |html_tag, instance|
  html = nil
  form_fields = %w[textarea input select]
  elements = Nokogiri::HTML::DocumentFragment.parse(html_tag).css 'label, ' + form_fields.join(', ')

  elements.each do |e|
    next unless form_fields.include?(e.node_name)

    errors = [instance.error_message].flatten.uniq.collect do |error|
      klass = begin
                instance.class.field_type.humanize
              rescue StandardError
                instance.class
              end
      "#{klass} #{error}"
    end
    html = %(<div class="field_with_errors">#{html_tag}</div><small class="has-text-danger">#{errors.join(', ')}</small>).html_safe
  end

  html
}
