% --------- 初始化 ---------
shape_width = shape_bounds(3) - shape_bounds(1);
shape_height = shape_bounds(4) - shape_bounds(2);
rectangle_area = shape_width * shape_height;
triangle_area = polyarea(triangle_points(:, 1), triangle_points(:, 2)); % Calculate the area of the triangle
shape_area = rectangle_area - triangle_area; % Total area of the shape

% Initialization
shapes = []; % Store generated shapes [x, y, param1, param2, ...]
total_shape_area = 0; % Total area of filled shapes
attempts = 0; % Attempt counter
% --------- 随机生成形状 ---------
while total_shape_area < target_area_ratio * shape_area && attempts < max_attempts
    geometry_x = shape_bounds(1) + (shape_bounds(3) - shape_bounds(1)) * rand();
    % 允许y坐标向上超出 max_radius
    geometry_y = shape_bounds(2) - max_radius + (shape_bounds(4) - shape_bounds(2) + max_radius) * rand();

    switch shape_type
        case 'circle'
            r = min_radius + (max_radius - min_radius) * rand();
            geometry_params = [r];

            % ===== 估算实际落入区域的面积（圆） =====
            n_samples = 1000;
            theta_samples = 2 * pi * rand(n_samples, 1);
            r_samples = sqrt(rand(n_samples, 1)) * r;
            px = r_samples .* cos(theta_samples);
            py = r_samples .* sin(theta_samples);
            pts = [px + geometry_x, py + geometry_y];
            in_idx = pts(:,1) >= shape_bounds(1) & pts(:,1) <= shape_bounds(3) & ...
                     pts(:,2) >= shape_bounds(2) & pts(:,2) <= shape_bounds(4);
            inside_ratio = sum(in_idx) / n_samples;
            geometry_area = inside_ratio * pi * r^2;

        case 'ellipse'
            ellipse_a = min_radius + (max_radius - min_radius) * rand();
            ellipse_b = min_radius + (max_radius - min_radius) * rand();
            ellipse_theta = 2 * pi * rand();
            geometry_params = [ellipse_a, ellipse_b, ellipse_theta];

            % ===== 估算实际落入区域的面积（椭圆） =====
            n_samples = 1000;
            theta_samples = 2 * pi * rand(n_samples, 1);
            r_samples = sqrt(rand(n_samples, 1));
            px = r_samples .* ellipse_a .* cos(theta_samples);
            py = r_samples .* ellipse_b .* sin(theta_samples);
            R = [cos(ellipse_theta), -sin(ellipse_theta); sin(ellipse_theta), cos(ellipse_theta)];
            pts = [px, py] * R';
            pts(:,1) = pts(:,1) + geometry_x;
            pts(:,2) = pts(:,2) + geometry_y;
            in_idx = pts(:,1) >= shape_bounds(1) & pts(:,1) <= shape_bounds(3) & ...
                     pts(:,2) >= shape_bounds(2) & pts(:,2) <= shape_bounds(4);
            inside_ratio = sum(in_idx) / n_samples;
            geometry_area = inside_ratio * pi * ellipse_a * ellipse_b;

        otherwise
            error('Unknown shape type');
    end

    % --------- 落在合法区域才进一步判断重叠 ---------
    if geometry_x - max(geometry_params) >= shape_bounds(1) && ...
       geometry_x + max(geometry_params) <= shape_bounds(3) && ...
       geometry_y + max(geometry_params) <= shape_bounds(4)

        % 与三角形重叠排除
        if ~is_shape_overlapping_triangle(geometry_x, geometry_y, geometry_params, shape_type, triangle_points)
            overlap = false;
            for i = 1:size(shapes, 1)
                dist_sq = (geometry_x - shapes(i, 1))^2 + (geometry_y - shapes(i, 2))^2;
                if dist_sq < (max(geometry_params) + max(shapes(i, 3:end)))^2
                    overlap = true;
                    break;
                end
            end
            if ~overlap
                shapes = [shapes; geometry_x, geometry_y, geometry_params];
                total_shape_area = total_shape_area + geometry_area;
            end
        end
    end
    attempts = attempts + 1;
end

% --------- 输出信息 ---------
fprintf('Number of generated shapes: %d\n', size(shapes, 1));
fprintf('Total area of filled shapes: %.2f\n', total_shape_area);
fprintf('Total area of the shape: %.2f\n', shape_area);
fprintf('Actual area ratio: %.2f\n', total_shape_area / shape_area);
