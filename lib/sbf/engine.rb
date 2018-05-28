require 'rails_admin'

module SBF
  class Engine < ::Rails::Engine
    # isolate_namespace EngineWithMigrations

    config.generators do |g|
      g.test_framework :rspec
    end

    initializer :append_migrations do |app|
      unless app.root.to_s == root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    initializer :assets do |config|
      Rails.application.config.assets.precompile += ['map.js', 'onemap.js']
    end
  end
end
