function ret = z_attach_BC(num,up,down)
    if num == -1
        ret = up;
    elseif num == 0
        ret = [up;down];
    elseif num == 1
        ret = [up;down;up];
    elseif num == 2
        ret = [up;down;up;down];
    elseif num == 3
        ret = [up;down;up;down;up];
    elseif num == 5
        ret = [up;down;up;down;up;down;up];
    elseif num == 7
        ret = [up;down;up;down;up;down;up;down;up];
    elseif num == 9
        ret = [up;down;up;down;up;down;up;down;up;down;up];    
    elseif num == 11
        ret = [up;down;up;down;up;down;up;down;up;down;up;down;up];
    elseif num == 13
        ret = [up;down;up;down;up;down;up;down;up;down;up;down;up;down;up];
    elseif num == 15
        ret = [up;down;up;down;up;down;up;down;up;down;up;down;up;down;up;down;up];
    elseif num == 17
        ret = [up;down;up;down;up;down;up;down;up;down;up;down;up;down;up;down;up;down;up];
    else
        fprintf('number of triangle exceeding 5 is not implemented!');
    end
end

