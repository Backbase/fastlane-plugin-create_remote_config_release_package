require 'fastlane/action'
require 'xcodeproj'
require_relative '../helper/create_remote_config_release_package_helper'

module Fastlane
  module Actions
    class CreateRemoteConfigReleasePackageAction < Action
      def self.description
        "Creates a Remote Config release package"
      end

      def self.authors
        ["George Nyakundi"]
      end

      def self.run(params)
        projectName = params[:project_name]
        appTitle = params[:app_title]
        campaignJSON = params[:campaign_json_path]
        parametersJSON = params[:parameters_json_path]
        bundleId = params[:bundle_id]
        projectFile = params[:project_file_path]

        locale_regexp = /^[A-Za-z]{2,3}([_-][A-Za-z]{4})?([_-]([A-Za-z]{2}|[0-9]{3}))?$/

        if File.file?(campaignJSON)
          campaign_hash = begin
            JSON.parse(File.read(campaignJSON))
          rescue StandardError
            nil
          end
        end

        if File.file?(parametersJSON)
          parameters_hash = begin
            JSON.parse(File.read(parametersJSON))
          rescue StandardError
            nil
          end
        end

        project = Xcodeproj::Project.open(projectFile)
        locales = []
        known_regions = project.root_object.known_regions
        known_regions.each do |region|
          if region =~ locale_regexp
            locales.push(region)
          end
        end

        project_hash = {
          "name" => projectName,
          "applications" => [
            "name" => bundleId,
            "title" => appTitle,
            "releases" => [
              "version" => other_action.get_version_number,
              "versionNumber" => other_action.get_build_number,
              "parameters" => parameters_hash || {},
              "campaignSlots" => campaign_hash || [],
              "locales" => locales
            ]
          ]
        }

        File.write("../project.json", project_hash.to_json)
        zip_name = "#{projectName}-project.zip"

        Dir.chdir("..") do
          sh("zip -FSr #{zip_name} project.json")
        end

        manifestHash = {
          "name" => projectName,
          "provisioningItems" => [
            "name" => projectName,
            itemType: "remote-config:/project",
            location: "/#{zip_name}"
          ]
        }

        File.write("../manifest.json", manifestHash.to_json)

        # Create a folder to where the provisioning package should be saved

        Dir.mkdir("releases")

        Dir.chdir("..") do
          sh("zip -FSr ./releases/provisioning_package.zip manifest.json #{zip_name}; rm #{zip_name}; rm manifest.json; rm project.json")
        end
        UI.success("provisioning_package.zip creation Completed")
        
        UI.success("Path: #{provisioning_package.zip.path}")
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        "This action creates a zip file with metadata required for release registration in the Remote config service"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :project_name,
            env_name: "RC_PROJECT_NAME",
            description: "specifies the project name configured in your client apps. Only use alphanumerics and dashes",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("No project_name given, pass using `project_name: 'project_name'`") unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :app_title,
            env_name: "RC_APP_TITLE",
            description: "specifies the title displayed in the Remote Config App",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("No app_title given, pass using `app_title: 'app_title'`") unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :bundle_id,
            env_name: "RC_BUNDLE_ID",
            description: "specifies the bundle id of the project",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("No App's bundle id given, pass using `bundle_id: 'bundle_id'`") unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :campaign_json_path,
            env_name: "RC_CAMPAIGN_JSON_PATH",
            description: "specifies the path to the campaign json slots",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("No campaign slots json file path given, pass using `campaign_json_path: 'campaign_json_path'`") unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :parameters_json_path,
            env_name: "RC_PARAMETERS_JSON_PATH",
            description: "specifies the path to the parameter json file",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("No parameter.json file path given, pass using `parameters_json_path: 'parameters_json_path'`") unless value && !value.empty?
            end
          ),
          FastlaneCore::ConfigItem.new(
            key: :project_file_path,
            env_name: "RC_PROJECT_FILE_PATH",
            description: "specifies the path to the Xcode project",
            optional: false,
            type: String,
            verify_block: proc do |value|
              UI.user_error!("No Xcode project path given, pass using `project_file_path: 'project_file_path'`") unless value && !value.empty?
            end
          )
        ]
      end

      def self.is_supported?(platform)
        [:ios].include?(platform)
        true
      end
    end
  end
end
