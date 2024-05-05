function ret = z_get_dechirp(num,up,down)
    if num == -1
        ret = down;
    elseif num == 0
        ret = [down;up];
    elseif num == 1
        ret = [down;up;down];
    elseif num == 2
        ret = [down;up;down;up];
    elseif num == 3
        ret = [down;up;down;up;down];
    elseif num == 5
        ret = [down;up;down;up;down;up;down];
    elseif num == 7
        ret = [down;up;down;up;down;up;down;up;down];
    elseif num == 9
        ret = [down;up;down;up;down;up;down;up;down;up;down];
    elseif num == 11
        ret = [down;up;down;up;down;up;down;up;down;up;down;up;down];
    elseif num == 13
        ret = [down;up;down;up;down;up;down;up;down;up;down;up;down;up;down];
    elseif num == 15
        ret = [down;up;down;up;down;up;down;up;down;up;down;up;down;up;down;up;down];
    elseif num == 17
        ret = [down;up;down;up;down;up;down;up;down;up;down;up;down;up;down;up;down;up;down];
    else
        fprintf('number of triangle exceeding 5 is not implemented!');
    end
end

