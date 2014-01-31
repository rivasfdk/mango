module MangoModule
  def is_mango_feature_available(feature)
    YAML::load(File.open("#{Rails.root.to_s}/config/global.yml"))['special_features'].include? feature
  end

  def get_mango_features()
    YAML::load(File.open("#{Rails.root.to_s}/config/global.yml"))['special_features']
  end
end
