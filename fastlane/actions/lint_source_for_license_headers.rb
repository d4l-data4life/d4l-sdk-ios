module Fastlane
  module Actions
    class LintSourceForLicenseHeadersAction < Action
      def self.run(params)
        license = File.read(params[:license]).split("\n").map { |line| "//  " + line }.join("\n")
        files = params[:files]
        should_autocorrect = params[:autocorrect] == true
        strict = params[:strict] ||= false
        violations = 0

        files.each do |filename|
          source = File.read(filename)
          unless source.start_with?(license)
            violations += 1
            UI.error "#{filename} does not contain the license header"
            if should_autocorrect
              source_by_line = source.split("\n")

              # Find comment header
              comment_index = source_by_line.each_index.
                select{|i| source_by_line[i].start_with?("//") }.
                map.
                with_index {|val, idx| val == idx ? val : nil}.
                compact

              # Remove old header
              source_by_line.slice!(comment_index.first..comment_index.last) if comment_index.length >= 1

              # Write source with new header
              corrected_source = license + "\n" + source_by_line.join("\n")
              File.write(filename, corrected_source)
            end
          end
        end

        if should_autocorrect
          UI.success "Found #{violations} violations and fixed them all"
        elsif violations > 0
          UI.user_error! "Found #{violations} violations. Correct these files manually or using `autocorrect` option"
        else
          UI.success "All source files contains the licence header. Good work 🎉"
        end
        if strict and violations > 0
          UI.error "Found #{violations} violations."
        end
      end


      def self.description
        "Lint the given source files for the license header"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :license,
                                       env_name: "LINT_LICENSE_PATH",
                                       description: "The path to the license file"),

          FastlaneCore::ConfigItem.new(key: :files,
                                       description: "An array containing the path to each file that should be linted",
                                       env_name: "LINT_LICENSE_HEADER_FILES",
                                       is_string: false),

          FastlaneCore::ConfigItem.new(key: :autocorrect,
                                       description: "Autocorrect source with wrong header (Default to `false`)",
                                       env_name: "LINT_AUTOCORRECT_LICENSE_HEADER_FILES",
                                       is_string: false,
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :strict,
                                       description: "Fail lane if any of the errors are encountered (Default to `false`)",
                                       env_name: "LINT_STRICT_LICENSE_HEADER_FILES",
                                       is_string: false,
                                       default_value: false),
        ]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
