# frozen_string_literal: true

# OPTIONS:
# https://github.com/ddnexus/pagy/blob/master/lib/config/pagy.rb
Pagy::VARS[:items] = 10

# Bulma extra: Add nav, nav_js and combo_nav_js helpers and templates for Bulma pagination
# See https://ddnexus.github.io/pagy/extras/bulma
require 'pagy/extras/bulma'
