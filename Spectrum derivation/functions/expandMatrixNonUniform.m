function expanded_mat = expandMatrixNonUniform(reduced_mat, original_size)
    % Extract the original dimensions
    original_rows = original_size(1);
    original_cols = original_size(2);
    
    % Get the size of the reduced matrix
    [reduced_rows, reduced_cols] = size(reduced_mat);
    
    % Calculate scaling factors for each dimension
    scale_row = original_rows / reduced_rows;
    scale_col = original_cols / reduced_cols;
    
    % Check if y-axis needs to be stretched more than x-axis
    if scale_row > scale_col
        stretched_mat = interp2(reduced_mat, linspace(1, reduced_cols, scale_col * reduced_cols), ...
                                        (1:reduced_rows)', 'linear', 0);
        expanded_mat = imresize(stretched_mat, [original_rows, original_cols], 'bicubic');
    else
        % Generate grid for original and reduced matrix
        [reduced_row_grid, reduced_col_grid] = meshgrid(1:reduced_cols, 1:reduced_rows);
        [original_row_grid, original_col_grid] = meshgrid(linspace(1, reduced_cols, original_cols), ...
                                                          linspace(1, reduced_rows, original_rows));
        
        % Perform bicubic interpolation
        expanded_mat = interp2(reduced_row_grid, reduced_col_grid, reduced_mat, ...
                               original_col_grid, original_row_grid, 'cubic');
    end
end
