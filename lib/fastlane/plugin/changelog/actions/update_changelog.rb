module Fastlane
  module Actions
    class UpdateChangelogAction < Action
      def self.run(params)
        changelog_path = params[:changelog_path] unless params[:changelog_path].to_s.empty?
        UI.error("CHANGELOG.md at path '#{changelog_path}' does not exist") unless File.exist?(changelog_path)
        
        section_identifier = params[:section_identifier] unless params[:section_identifier].to_s.empty?
        escaped_section_identifier = section_identifier[/\[(.*?)\]/, 1]

        new_section_identifier = params[:updated_section_identifier] unless params[:updated_section_identifier].to_s.empty?
        # new_section_content = params[:updated_section_content] unless (params[:updated_section_content].to_s.empty?)
        
        UI.message "Starting to update #{section_identifier} section of '#{changelog_path}'"

        # Read & update file content
        file_content = ""
        File.open(changelog_path, "r") do |file|
          file.each_line do |line|
            # Find line matching section identifier
            if line =~ /\#{2}\s?\[#{escaped_section_identifier}\]/
              found_identifying_section = true
            end

            # Update section identifier (if found)
            if !new_section_identifier.empty? && found_identifying_section
              section_name = section_identifier[/\[(.*?)\]/, 1]

              line_old = line.dup
              line.sub!(section_name, new_section_identifier)
              found_identifying_section = false
              
              UI.message "Old section identifier: #{line_old.delete!("\n")}"
              UI.message "New section identifier: #{line.delete("\n")}"

              # Output updated line
              file_content.concat(line)
              next
            end

            # TODO: implement updating of section content

            # Output read line
            file_content.concat(line)
          end
        end

        # Write updated content to file
        changelog = File.open(changelog_path, "w")
        changelog.puts(file_content)
        changelog.close
        UI.success("Successfuly updated #{changelog_path}")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Updates content of a section of your project CHANGELOG.md file"
      end

      def self.details
        "Use this action to update content of an arbitrary section of your project CHANGELOG.md"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :changelog_path,
                                       env_name: "FL_UPDATE_CHANGELOG_PATH_TO_CHANGELOG",
                                       description: "The path to your project CHANGELOG.md",
                                       is_string: true,
                                       default_value: "./CHANGELOG.md",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :section_identifier,
                                       env_name: "FL_UPDATE_CHANGELOG_SECTION_IDENTIFIER",
                                       description: "The unique section identifier to update content of",
                                       is_string: true,
                                       default_value: "[Unreleased]",
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Sections (##) in CHANGELOG format must be encapsulated in []") unless value.start_with?("[") && value.end_with?("]")
                                         UI.user_error!("Sections (##) in CHANGELOG format cannot be empty") if value[/\[(.*?)\]/, 1].empty?
                                       end),
          FastlaneCore::ConfigItem.new(key: :updated_section_identifier,
                                       env_name: "FL_UPDATE_CHANGELOG_UPDATED_SECTION_IDENTIFIER",
                                       description: "The updated unique section identifier",
                                       is_string: true,
                                       optional: true)
          # FastlaneCore::ConfigItem.new(key: :updated_section_content,
          #                              env_name: "FL_UPDATE_CHANGELOG_UPDATED_SECTION_CONTENT",
          #                              description: "The updated section content",
          #                              is_string: true,
          #                              optional: true)
        ]
      end

      def self.authors
        ["pajapro"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
