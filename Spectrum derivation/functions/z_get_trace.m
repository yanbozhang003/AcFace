function tr_list = z_get_trace(username,user_all,mask_i,mask_all,distance_all,config)    
        user_index = find(strcmp(user_all,username));

        tr_head = (user_index-1)*length(distance_all)*length(mask_all)+1;
        tr_tail = user_index*length(distance_all)*length(mask_all);

        if mask_i == 1
            tr_list = tr_head+1:2:tr_tail;
        elseif mask_i == 0
            tr_list = tr_head:2:tr_tail-1;
        end

        tr_list= tr_list(config.distance_index);
end

