module MangoModule
  def is_mango_feature_available(feature)
    special_features = YAML::load(File.open("#{Rails.root.to_s}/config/global.yml"))['special_features']
    return special_features.include? feature
  end
  def get_mango_features()
    YAML::load(File.open("#{Rails.root.to_s}/config/global.yml"))['special_features']
  end
end
