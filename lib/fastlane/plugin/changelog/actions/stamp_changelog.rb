module Fastlane
  module Actions
    class StampChangelogAction < Action
      def self.run(params)
        changelog_path = params[:changelog_path] unless params[:changelog_path].to_s.empty?
        UI.error("CHANGELOG.md at path '#{changelog_path}' does not exist") unless File.exist?(changelog_path)

        # 1. Update [Unreleased] section with provided identifier
        section_identifier = params[:section_identifier] unless params[:section_identifier].to_s.empty?
        Actions::UpdateChangelogAction.run(changelog_path: changelog_path,
                                          section_identifier: "[Unreleased]",
                                          updated_section_identifier: section_identifier)

        file_content = ""

        # 2. Create new [Unreleased] section (placeholder)
        inserted_unreleased = false
        File.open(changelog_path, "r") do |file|
          file.each_line do |line|
            # Find the first section identifier
            if !inserted_unreleased && line =~ /\#{2}\s?\[(.*?)\]/
              unreleased_section = "## [Unreleased]"
              line = "#{unreleased_section}\n\n#{line}"
              inserted_unreleased = true

              UI.message("Created [Unreleased] placeholder section")

              # Output updated line
              file_content.concat(line)
              next
            end

            # Output read line
            file_content.concat(line)
          end
        end

        # 3. Create link to Github tags diff
        unless params[:git_tag].empty?
          last_line = file_content.lines.last
          previous_section_name = last_line[/\[(.*?)\]/, 1]
          previous_previous_tag = %r{(?<=compare\/)(.*)?(?=\.{3})}.match(last_line)
          previous_tag = /(?<=\.{3})(.*)?/.match(last_line)

          last_line.sub!(previous_tag.to_s, params[:git_tag]) # Replace previous tag with new
          last_line.sub!(previous_previous_tag.to_s, previous_tag.to_s) # Replace previous-previous tag with previous
          last_line.sub!(previous_section_name.to_s, section_identifier) # Replace section identifier

          UI.message("Created link to Github tags diff")

          file_content.concat(last_line)
        end

        # 4. Write updated content to file
        changelog = File.open(changelog_path, "w")
        changelog.puts(file_content)
        changelog.close
        UI.success("Successfuly stamped #{section_identifier} in #{changelog_path}")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Stamps the [Unreleased] section with provided identifier in your project CHANGELOG.md file"
      end

      def self.details
        "Use this action to stamp the [Unreleased] section with provided identifier in your project CHANGELOG.md. Additionally, you can provide git tag
        associated with this section. `stamp_changelog` will then create a new link to diff between this and previous section's tag on Github"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :changelog_path,
                                       env_name: "FL_STAMP_CHANGELOG_PATH_TO_CHANGELOG",
                                       description: "The path to your project CHANGELOG.md",
                                       is_string: true,
                                       default_value: "./CHANGELOG.md",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :section_identifier,
                                       env_name: "FL_STAMP_CHANGELOG_SECTION_IDENTIFIER",
                                       description: "The unique section identifier to stamp the [Unreleased] section with",
                                       is_string: true),
          FastlaneCore::ConfigItem.new(key: :git_tag,
                                       env_name: "FL_STAMP_CHANGELOG_GIT_TAG",
                                       description: "The git tag associated with this section",
                                       is_string: true,
                                       optional: true)
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