module Hue
  def self.sample_utterances
    File.read(File.expand_path('../../../skills_config/sample_utterances.txt', __FILE__))
  end
end
