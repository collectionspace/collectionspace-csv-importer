# frozen_string_literal: true

class SystemInformation
  def self.gems
    Gem::Specification.sort_by do |g|
      [g.name.downcase, g.version]
    end
  end

  def self.system_summary(system)
    system = JSON.parse(system)
    {
      cpu: system['cpu']['cores'],
      freemem: system['memory']['free'],
      machine: system['kernel']['machine'],
      os: system['kernel']['os'],
      processor: system['kernel']['processor'],
      totalmem: system['memory']['total'],
      uptime: system['uptime']
    }
  end

  def self.system
    Ohai::System.new.all_plugins.to_json
  end
end
