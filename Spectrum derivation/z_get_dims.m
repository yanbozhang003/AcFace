function [x_vec,y_vec,z_vec] = z_get_dims(config,faceArrayDist,Depth)
    y_vec = faceArrayDist + Depth;
    if config.resolution == 2
        x_vec = config.x_range_min:0.2:config.x_range_max;
        z_vec = config.z_range_max:-0.2:config.z_range_min;
    elseif config.resolution == 1
        x_vec = config.x_range_min:1:config.x_range_max;
        z_vec = config.z_range_max:-1:config.z_range_min;
    end
end

