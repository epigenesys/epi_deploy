require 'spec_helper'
require 'epi_deploy/stages_extractor'


describe EpiDeploy::StagesExtractor do
  
  subject do
    Dir.chdir(File.join(File.dirname(__FILE__), '../..', 'fixtures')) do
      described_class.new
    end
  end
  
  describe '#multi_customer_stage?' do
    it 'returns true if the stage is for multiple customers' do
      expect(subject.multi_customer_stage?('production')).to be true
    end
    
    it 'returns false if the stage is not for multiple customers' do
      expect(subject.multi_customer_stage?('demo')).to be false
    end
  end
  
  describe '#valid_stage?' do
    specify "a multi-customer stage is valid" do
      expect(subject.valid_stage?('production')).to be true
    end
    
    specify "a single-customer stage is valid" do
      expect(subject.valid_stage?('demo')).to be true
    end
    
    specify "a specific customer stage is valid" do
      expect(subject.valid_stage?('production.epigenesys')).to be true
    end
    
    specify "a stage without a config file is not valid" do
      expect(subject.valid_stage?('qa')).to be false
    end
  end

  describe '#environments' do
    specify 'it returns a list of environments' do
      expect(subject.environments).to match_array ['production', 'demo']
    end
  end

  describe '#all_stages' do
    specify 'it returns of all deployment stages' do
      expect(subject.all_stages).to match_array ['production.epigenesys', 'production.genesys', 'demo']
    end
  end

  describe '#multi_customer_stages' do
    specify 'it returns only stages that have multiple customers for the same environment' do
      expect(subject.multi_customer_stages).to match_array ['production']
    end
  end

  describe '#stages_for_stage_or_environment' do
    specify 'it returns the deployable stages for a multi-customer environment' do
      expect(subject.stages_for_stage_or_environment('production')).to match_array ['production.epigenesys', 'production.genesys']
    end

    specify 'it returns the deployment stage itself for a single customer environment' do
      expect(subject.stages_for_stage_or_environment('demo')).to match_array ['demo']
    end

    specify 'it returns the deployment stage for a fully qualified stage in a multi-customer environment' do
      expect(subject.stages_for_stage_or_environment('production.epigenesys')).to match_array ['production.epigenesys']
    end
  end
end