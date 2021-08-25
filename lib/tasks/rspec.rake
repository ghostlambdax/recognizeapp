namespace :spec do
 
  if defined?(RSpec)
    desc 'Run all specs in spec directory (excluding request/integration specs)'
    RSpec::Core::RakeTask.new(:nofeatures) do |task|
      file_list = FileList['spec/**/*_spec.rb']

      %w(features feature).each do |exclude|
        file_list = file_list.exclude("spec/#{exclude}/**/*_spec.rb")
      end

      task.pattern = file_list
    end
  end
end