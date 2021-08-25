# frozen_string_literal: true

# NOTE: To update the manifest, modify any of the relevant files:
#
#       * config/ms_teams/color.png
#       * config/ms_teams/outline.png
#       * config/ms_teams/manifest.json
#
#       Then this script will generate the zip file for sideloading or publishing in MsTeams App Studio
#
# NOTE: to be called via rake task.
#       Ex. For local development: `bundle exec rake recognize:generate_ms_teams_manifest`
#       Ex. For Patagonia/Staging: `HOST=patagonia.recognizeapp.com bundle exec rake recognize:generate_ms_teams_manifest`
#       Ex. For Production: `HOST=recognizeapp.com bundle exec rake recognize:generate_ms_teams_manifest`
#
class MsTeamsTasks

  GUIDS = {
    "recognizedev.ngrok.io" => "00928935-88fb-4492-928e-e7315793f383",
    "recognizedev2.ngrok.io" => "ae5b786f-40db-4a30-9c2c-195a6d90d050",
    "l.recognizeapp.com" => "e0b308c8-ae6f-40b2-a7fa-f42f9e949b47",
    "recognizeapp.com" => "bbcb7b0c-c687-4be0-91e3-362afebbbcd0",
    "demo.recognizeapp.com" => "61acfb8e-334f-4467-923a-b4bcb4eedc6c",
    "patagonia.recognizeapp.com" => "cb3a0902-2695-473d-b186-77698577ff02"
  }.freeze

  def self.generate_manifest_zip
    ManifestGenerator.generate!
  end

  class ManifestGenerator
    MANIFEST_FILE_PATH = File.join(Rails.root, "config/ms_teams/manifest.json")

    def self.generate!
      new.generate!
    end

    def file
      @file ||= File.read(MANIFEST_FILE_PATH)
    end

    def generate!
      update_guid
      update_name
      update_personal_tab_urls
      update_tab_configuration_urls
      generate_zip
    end

    def generate_zip
      zipfile_name = File.join(Rails.root, "config/ms_teams/ms_teams_manifest_#{host}.zip")
      input_filenames = ["manifest.json", "color.png", "outline.png"]

      # remove previous file
      File.delete(zipfile_name) if File.exist?(zipfile_name)
      Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
        input_filenames.each do |filename|
          # Two arguments:
          # - The name of the file as it will appear in the archive
          # - The original file, including the path to find it
          zipfile.add(filename, File.join(Rails.root, "config/ms_teams/#{filename}"))
        end
        zipfile.get_output_stream("manifest.json") { |f| f.write json.to_json }
      end
      puts "Manifest generated at: #{zipfile_name}"
    end

    def host
      ENV['HOST'] || Rails.application.config.host
    end

    def json
      @json ||= JSON.parse(file)
    end

    def prod?
      host == "recognizeapp.com"
    end

    def update_name
      return if prod?
      json["name"]["short"] = "Rcgnz-#{host}"[0..29] # 30 char max
      json["name"]["full"] = "Recognize-#{host}"
    end

    UNKOWN_HOST_MSG = "New host detected! Please add your hostname to MsTeamsTasks::GUIDS with a unique GUID. You can generate a guid in the AppStudio manifest editor."
    def update_guid
      raise UNKOWN_HOST_MSG if GUIDS[host].blank?
      json["id"] = GUIDS[host]
    end

    def update_personal_tab_urls
      tabs = json["staticTabs"]
      tabs.each_with_index do |tab, i|

        ["contentUrl", "websiteUrl"].each do |key|
          current_tab_url = tab[key]
          current_tab_uri = URI.parse(current_tab_url)
          new_tab_url = current_tab_url.gsub(current_tab_uri.host, host)
          json["staticTabs"][i][key] = new_tab_url
        end
      end
    end

    def update_tab_configuration_urls
      tabs = json["configurableTabs"]
      tabs.each_with_index do |tab, i|
        current_tab_url = tab["configurationUrl"]
        current_tab_uri = URI.parse(current_tab_url)
        new_tab_url = current_tab_url.gsub(current_tab_uri.host, host)
        json["configurableTabs"][i]["configurationUrl"] = new_tab_url
      end
    end
  end
end
