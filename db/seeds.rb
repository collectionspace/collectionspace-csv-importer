# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# Setup roles first
Role.find_or_create_by!(name: 'Admin')
Role.find_or_create_by!(name: 'Manager')
Role.find_or_create_by!(name: 'Member')

Group.find_or_create_by!(supergroup: true) do |group|
  group.name = 'Default'
  group.supergroup = true
  group.description = 'Default group.'
end
# Setup initial set of mappers (this may change)
Mapper.refresh

connections = [
  {
    name: 'Core Dev Server',
    url: 'https://core.dev.collectionspace.org/cspace-services',
    username: 'admin@core.collectionspace.org',
    password: 'Administrator',
    enabled: true,
    primary: false,
    profile: 'core-6.1.0'
  },
  {
    name: 'Fcart Dev Server',
    url: 'https://fcart.dev.collectionspace.org/cspace-services',
    username: 'admin@fcart.collectionspace.org',
    password: 'Administrator',
    enabled: true,
    primary: false,
    profile: 'fcart-3.0.1'
  }
]

User.find_or_create_by!(superuser: true) do |user|
  user.email = Rails.configuration.superuser_email
  user.enabled = true
  user.password = Rails.configuration.superuser_password
  user.password_confirmation = Rails.configuration.superuser_password
  user.role = Role.admin
  connections.each { |c| user.connections.build(c) }
end

if ENV.fetch('RAILS_ENV', 'development') == 'development'
  User.find_or_create_by!(email: 'admin@collectionspace.org') do |user|
    user.enabled = true
    user.password = Rails.configuration.superuser_password
    user.password_confirmation = Rails.configuration.superuser_password
    user.role = Role.admin
    connections.each { |c| user.connections.build(c) }
  end

  groups = [
    { name: 'Fish', domain: 'fish.net', email: 'support@fish.net', enabled: false },
    { name: 'Fruit', domain: 'fruit.com', email: 'support@fruit.com' },
    { name: 'Groceries', domain: 'groceries.biz', email: 'support@groceries.biz' },
    { name: 'Veg', domain: 'veg.edu', email: 'support@veg.edu' }
  ]
  groups.each do |food|
    Group.find_or_create_by!(name: food[:name]) do |group|
      group.description = "#{food[:name]} group."
      group.domain = food[:domain]
      group.email = food[:email]
      group.enabled = food.fetch(:enabled, true)
    end
  end

  users = [
    'manager@fish.net',
    'salmon@fish.net',
    'tuna@fish.net',
    'manager@fruit.com',
    'apple@fruit.com',
    'banana@fruit.com',
    'manager@veg.edu',
    'brocolli@veg.edu',
    'carrot@veg.edu'
  ]
  users.each do |email|
    u = User.find_or_create_by!(email: email) do |user|
      user.enabled = true
      user.password = 'password'
      user.password_confirmation = 'password'
    end
    u.groups << Group.where(name: 'Groceries').first
  end
end
