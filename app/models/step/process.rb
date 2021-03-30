# frozen_string_literal: true

module Step
  class Process < ApplicationRecord
    include WorkflowMetadata
    belongs_to :batch

    # after_initialize do |process|
    #   @config = JSON.parse(process.batch.batch_config)
    #   process.update(check_terms: false) unless config_check_terms?
    #   process.update(check_records: false) unless config_check_records?
    # end

    def check_records?
      check_records
    end

    def check_terms?
      check_terms
    end

    def name
      :processing
    end

    def prefix
      :pro
    end

    # def config_check_terms?
    #   # if not specified in collectionspace-mapper config, defaults to true
    #   return true unless @config.key?('check_terms')
    #   # otherwise return boolean value explicitly given in config
    #   @config['check_terms']
    # end

    # def config_check_records?
    #   # if not specified in collectionspace-mapper config, defaults to true
    #   return true unless @config.key?('check_record_status')
    #   # otherwise return boolean value explicitly given in config
    #   @config['check_record_status']
    # end
  end
end
