function rx_frame_mat = z_frame_segment(rx_bb_t,chirp_head,N_cycles,N_BC,L_chirp)
    L_symbol = L_chirp*(N_BC+2);
    L_step = L_chirp*2;

    rx_frame_mat = zeros(L_symbol,N_cycles);
    for symbol_idx = 1:1:N_cycles
        s_head = chirp_head + (symbol_idx-1)*L_step + 1;
        s_tail = s_head + L_symbol - 1;
        
        rx_frame_mat(:,symbol_idx) = rx_bb_t(s_head:s_tail);
    end
end

