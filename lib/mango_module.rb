module MangoModule
  def is_mango_feature_available(feature)
    features = YAML::load(File.open("#{Rails.root.to_s}/config/global.yml"))['special_features']
    features.nil? ? false : features.include?(feature)
  end

  def get_mango_features()
    YAML::load(File.open("#{Rails.root.to_s}/config/global.yml"))['special_features'] || []
  end
end
