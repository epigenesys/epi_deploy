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
  
end