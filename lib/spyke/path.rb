require 'addressable/template'
require 'spyke/rfc_converter'

module Spyke
  class InvalidPathError < StandardError; end
  class Path
    attr_reader :pattern, :params

    def initialize(pattern, params = {})
      @pattern = pattern
      @params = params.symbolize_keys
    end

    def join(other_path)
      self.class.new File.join(path, other_path.to_s), @params
    end

    def to_s
      path
    end

    def variables
      @variables ||= uri_template.variables.map(&:to_sym)
    end

    private

      def uri_template
        @uri_template ||= Addressable::Template.new(pattern_with_rfc_style_parens)
      end

      def pattern_with_rfc_style_parens
        RfcConverter.new(@pattern).convert
      end

      def path
        validate_required_variables!
        uri_template.expand(@params).to_s.chomp('/')
      end

      def validate_required_variables!
        if missing_required_variables.any?
          raise Spyke::InvalidPathError, "Missing required variables: #{missing_required_variables.join(', ')} in #{@pattern}. Mark optional variables with parens eg: (:param)"
        end
      end

      def missing_required_variables
        required_variables - variables_with_values
      end

      def variables_with_values
        @params.map do |key, value|
          key if value.present?
        end.compact
      end

      def required_variables
        variables - optional_variables
      end

      def optional_variables
        @pattern.scan(/\(\/?:(\w+)\)/).flatten.map(&:to_sym)
      end
  end
end
