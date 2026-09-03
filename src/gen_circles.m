% 参数设置
% 设置水平层形状
shape_bounds0 =  [0, 0, 15000, 3500]; % 整个模型边界 [xmin, ymin, xmax, ymax]
shape_bounds1 =  [0, 0, 15000, 500]; % 顶部矩形边界（刚性物体） [xmin, ymin, xmax, ymax]
shape_bounds2 =  [0, 3000, 15000, 3500]; % 底部矩形边界（刚性物体） [xmin, ymin, xmax, ymax]
shape_bounds3 =  [0, 2500, 15000, 3000]; % 水平层 [xmin, ymin, xmax, ymax]


shape_bounds = [0, 500, 15000, 2500]; % 矩形边界 [xmin, ymin, xmax, ymax]
triangle_points = [10000, 2500; 12500, 1000; 15000, 2500]; % 三角形的三个顶点 [x1, y1; x2, y2; x3, y3]
min_radius = 45; % 最小半径（用于椭圆的长轴和短轴）
max_radius = 400.0; %最大半径（用于椭圆的长轴和短轴）
target_area_ratio = 0.2; % 目标面积比例（填充形状的总面积 / 形状总面积）
max_attempts = 10000; % 最大尝试次数

% 填充形状选项
shape_type = 'ellipse'; % 可选：'circle', 'ellipse', 

% 计算形状的总面积（矩形面积 - 三角形面积）
shape_width = shape_bounds(3) - shape_bounds(1);
shape_height = shape_bounds(4) - shape_bounds(2);
rectangle_area = shape_width * shape_height;
triangle_area = polyarea(triangle_points(:, 1), triangle_points(:, 2)); % 计算三角形面积
shape_area = rectangle_area - triangle_area; % 形状的总面积

% 初始化
shapes = []; % 存储生成的形状 [x, y, param1, param2, ...]
total_shape_area = 0; % 填充形状的总面积
attempts = 0; % 尝试次数计数器



% 生成随机形状
while total_shape_area < target_area_ratio * shape_area && attempts < max_attempts
    % 生成随机形状
    x = shape_bounds(1) + (shape_bounds(3) - shape_bounds(1)) * rand();
    y = shape_bounds(2) + (shape_bounds(4) - shape_bounds(2)) * rand();
    
    switch shape_type
        case 'circle'
            r = min_radius + (max_radius - min_radius) * rand();
            params = [r];
            area = pi * r^2;
        case 'ellipse'
            a = min_radius + (max_radius - min_radius) * rand(); % 长轴
            b = min_radius + (max_radius - min_radius) * rand(); % 短轴
            theta = 2 * pi * rand(); % 旋转角度
            params = [a, b, theta];
            area = pi * a * b;

        otherwise
            error('未知的形状类型');
    end
    
    % 检查形状是否在矩形内且不与三角形重叠
    if x - max(params) >= shape_bounds(1) && x + max(params) <= shape_bounds(3) && ...
       y - max(params) >= shape_bounds(2) && y + max(params) <= shape_bounds(4)
        % 检查形状是否与三角形重叠
        if ~is_shape_overlapping_triangle(x, y, params, shape_type, triangle_points)
            % 检查是否与已有形状重叠
            overlap = false;
            for i = 1:size(shapes, 1)
                dist_sq = (x - shapes(i, 1))^2 + (y - shapes(i, 2))^2;
                if dist_sq < (max(params) + max(shapes(i, 3:end)))^2
                    overlap = true;
                    break;
                end
            end
            
            % 如果没有重叠，添加到形状列表并更新总面积
            if ~overlap
                shapes = [shapes; x, y, params];
                total_shape_area = total_shape_area + area;
            end
        end
    end
    attempts = attempts + 1;
end

% 输出结果
fprintf('生成的形状数量: %d\n', size(shapes, 1));
fprintf('填充形状的总面积: %.2f\n', total_shape_area);
fprintf('形状的总面积: %.2f\n', shape_area);
fprintf('实际面积比例: %.2f\n', total_shape_area / shape_area);

% 绘制结果
figure;

hold on;
% 绘制矩形边界
rectangle('Position', [shape_bounds(1), shape_bounds(2), ...
                      shape_bounds(3) - shape_bounds(1), shape_bounds(4) - shape_bounds(2)], ...
          'EdgeColor', 'k', 'LineWidth', 2);
% 绘制三角形边界
patch(triangle_points(:, 1), triangle_points(:, 2), 'k', 'EdgeColor', 'k', 'FaceColor', 'none', 'LineWidth', 2);
% 绘制填充形状
for i = 1:size(shapes, 1)
    x = shapes(i, 1);
    y = shapes(i, 2);
    params = shapes(i, 3:end);
    switch shape_type
        case 'circle'
            r = params(1);
            rectangle('Position', [x - r, y - r, 2 * r, 2 * r], ...
                      'Curvature', [1, 1], 'EdgeColor', 'b', 'FaceColor', [0, 0, 1, 0.5]);
        case 'ellipse'
            a = params(1);
            b = params(2);
            theta = params(3);
            draw_ellipse(x, y, a, b, theta);
        case 'rectangle'
            w = params(1);
            h = params(2);
            theta = params(3);
            draw_rectangle(x, y, w, h, theta);
        case 'polygon'
            polygon_points = params;
            patch(polygon_points(:, 1), polygon_points(:, 2), 'b', 'EdgeColor', 'b', 'FaceColor', [0, 0, 1, 0.5]);
    end
end
title(['随机形状填充（', shape_type, '）']);
xlabel('X');
ylabel('Y');
set(gca, 'YDir', 'reverse')
hold on
% 检查点是否在三角形内

grid_size = [(ny-1)*my, (nx-1)*mx];
grid_x = linspace(shape_bounds0(1), shape_bounds0(3), (nx-1)*mx);
grid_y = linspace(shape_bounds0(2), shape_bounds0(4), (ny-1)*my);
[X, Y] = meshgrid(grid_x, grid_y);

% 初始化网格点状态矩阵
grid_status = zeros((ny-1)*my, (nx-1)*mx);

% 检查每个网格点是否在生成的圆内
for i = 1:(ny-1)*my
    for j = 1:(nx-1)*mx
        px = X(i, j);
        py = Y(i, j);
         %3 设置上下水平边界
             if py <= shape_bounds1(4) || py > shape_bounds2(2)
            grid_status(i, j) = 2;
             end
        %0 设置洋壳
            if  py > shape_bounds3(2) && py <= shape_bounds3(4)
                grid_status(i, j) = 6;
            end
        %4 设置俯冲渠道的形状
        if px >= shape_bounds(1) && px <= shape_bounds(3) && ...
           py >= shape_bounds(2) && py <= shape_bounds(4)  && ~is_point_in_triangle(px, py, triangle_points)
        
                grid_status(i, j) = 3; 
        end
       %1 设置block的形状 
        switch shape_type
        case 'circle'
            for k = 1:size(shapes, 1)
            x = shapes(k, 1);
            y = shapes(k, 2);
            r = shapes(k, 3);
            if (px - x)^2 + (py - y)^2 <= r^2
            grid_status(i, j) = 4; %%这里最好对应相
                break;
            end
            end
         case 'ellipse'
            for k = 1:size(shapes, 1)
            x = shapes(k, 1);
            y = shapes(k, 2);
            a = shapes(k, 3);
            b = shapes(k, 4);
            theta = shapes(k, 5);
            if is_point_in_ellipse(px, py, x, y, a, b, theta)
                grid_status(i, j) = 4; % 在椭圆内
                break;
            end
            end
        end

     %2 设置海山的形状 
             if is_point_in_triangle(px, py, triangle_points)
            grid_status(i, j) = 7; % 在三角形内
             end
    
    


    end
end









function inside = is_point_in_triangle(px, py, tri_points)
    % 使用重心坐标法判断点是否在三角形内
    v0 = tri_points(3, :) - tri_points(1, :);
    v1 = tri_points(2, :) - tri_points(1, :);
    v2 = [px, py] - tri_points(1, :);
    
    dot00 = dot(v0, v0);
    dot01 = dot(v0, v1);
    dot02 = dot(v0, v2);
    dot11 = dot(v1, v1);
    dot12 = dot(v1, v2);
    
    inv_denominator = 1 / (dot00 * dot11 - dot01 * dot01);
    u = (dot11 * dot02 - dot01 * dot12) * inv_denominator;
    v = (dot00 * dot12 - dot01 * dot02) * inv_denominator;
    
    inside = (u >= 0) && (v >= 0) && (u + v <= 1);
end

% 检查形状是否与三角形重叠
function overlap = is_shape_overlapping_triangle(x, y, params, shape_type, tri_points)
    % 根据形状类型检查是否与三角形重叠
    switch shape_type
        case 'circle'
            r = params(1);
            overlap = is_circle_overlapping_triangle(x, y, r, tri_points);
        case 'ellipse'
            a = params(1); % 长轴
            b = params(2); % 短轴
            theta = params(3); % 旋转角度
            overlap = is_ellipse_overlapping_triangle(x, y, a, b, theta, tri_points);
       
        otherwise
            error('未知的形状类型');
    end
end

% 检查圆形是否与三角形重叠
function overlap = is_circle_overlapping_triangle(x, y, r, tri_points)
    % 检查圆心是否在三角形内
    if is_point_in_triangle(x, y, tri_points)
        overlap = true;
        return;
    end
    
    % 检查圆形的边界是否与三角形的边相交
    for i = 1:3
        p1 = tri_points(i, :);
        p2 = tri_points(mod(i, 3) + 1, :);
        
        % 计算线段到圆心的距离
        a = (x - p1(1)) * (p2(1) - p1(1)) + (y - p1(2)) * (p2(2) - p1(2));
        b = (p2(1) - p1(1))^2 + (p2(2) - p1(2))^2;
        t = max(0, min(1, a / b));
        nearest_x = p1(1) + t * (p2(1) - p1(1));
        nearest_y = p1(2) + t * (p2(2) - p1(2));
        dist_sq = (x - nearest_x)^2 + (y - nearest_y)^2;
        
        % 如果距离小于半径，则圆形与边相交
        if dist_sq < r^2
            overlap = true;
            return;
        end
    end
    
    % 检查三角形的顶点是否在圆形内
    for i = 1:3
        dist_sq = (x - tri_points(i, 1))^2 + (y - tri_points(i, 2))^2;
        if dist_sq < r^2
            overlap = true;
            return;
        end
    end
    
    % 如果没有重叠
    overlap = false;
end

% 检查椭圆是否与三角形重叠
% 检查椭圆的边界是否与三角形的边相交
function overlap = is_ellipse_overlapping_triangle(x, y, a, b, theta, tri_points)
    % 将椭圆和三角形的点转换到椭圆的标准坐标系
    R = [cos(theta), -sin(theta); sin(theta), cos(theta)]; % 旋转矩阵
    inv_R = [cos(theta), sin(theta); -sin(theta), cos(theta)]; % 逆旋转矩阵
    
    % 将三角形的顶点转换到椭圆的标准坐标系
    tri_points_transformed = (tri_points - [x, y]) * inv_R;
    
    % 检查三角形的顶点是否在椭圆内
    for i = 1:3
        px = tri_points_transformed(i, 1);
        py = tri_points_transformed(i, 2);
        if (px^2 / a^2) + (py^2 / b^2) < 1
            overlap = true;
            return;
        end
    end
    
    % 检查椭圆的边界是否与三角形的边相交
    % 遍历三角形的三条边
    for i = 1:3
        p1 = tri_points_transformed(i, :);
        p2 = tri_points_transformed(mod(i, 3) + 1, :);
        
        % 计算线段到椭圆中心的距离
        a2 = a^2;
        b2 = b^2;
        dx = p2(1) - p1(1);
        dy = p2(2) - p1(2);
        A = dx^2 / a2 + dy^2 / b2;
        B = 2 * (p1(1) * dx / a2 + p1(2) * dy / b2);
        C = p1(1)^2 / a2 + p1(2)^2 / b2 - 1;
        
        % 计算判别式
        discriminant = B^2 - 4 * A * C;
        
        % 如果判别式大于等于 0，则线段与椭圆相交
        if discriminant >= 0
            overlap = true;
            return;
        end
    end
     if is_point_in_triangle(x, y, tri_points)
        overlap = true;
        return;
    end
    
    % 如果没有重叠
    overlap = false;
end


% 绘制椭圆
function draw_ellipse(x, y, a, b, theta)
    t = linspace(0, 2 * pi, 100);
    ellipse_x = a * cos(t);
    ellipse_y = b * sin(t);
    R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
    ellipse_points = [ellipse_x; ellipse_y]' * R;
    patch(x + ellipse_points(:, 1), y + ellipse_points(:, 2), 'b', 'EdgeColor', 'b', 'FaceColor', 'b');
end

% 绘制矩形
function draw_rectangle(x, y, w, h, theta)
    rect_points = [-w/2, -h/2; w/2, -h/2; w/2, h/2; -w/2, h/2];
    R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
    rect_points = rect_points * R;
    patch(x + rect_points(:, 1), y + rect_points(:, 2), 'b', 'EdgeColor', 'b', 'FaceColor', 'b');
end

function inside = is_point_in_ellipse(px, py, x, y, a, b, theta)
    % 将点转换到椭圆的标准坐标系
    R = [cos(theta), -sin(theta); sin(theta), cos(theta)]; % 旋转矩阵
    inv_R = [cos(theta), sin(theta); -sin(theta), cos(theta)]; % 逆旋转矩阵
    
    % 将点转换到椭圆的标准坐标系
    point_transformed = ([px, py] - [x, y]) * inv_R;
    
    % 检查点是否在椭圆内
    inside = (point_transformed(1)^2 / a^2) + (point_transformed(2)^2 / b^2) <= 1;
end