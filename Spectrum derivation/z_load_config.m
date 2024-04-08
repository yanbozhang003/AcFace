function [config,settings] = z_load_config(settings_folder)
    config = load([settings_folder,'config.mat']).config;
    settings = load([settings_folder,'settings.mat']).setting;
end

