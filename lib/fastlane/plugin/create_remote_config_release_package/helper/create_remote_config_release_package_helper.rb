require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class CreateRemoteConfigReleasePackageHelper
      # class methods that you define here become available in your action
      # as `Helper::CreateRemoteConfigReleasePackageHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the create_remote_config_release_package plugin helper!")
      end
    end
  end
end
