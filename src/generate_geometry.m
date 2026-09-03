% clear all
% Generate the model geomerty
plot_initial_model = 1;
% 1. set number of model nodes
% nx      =   751;
% ny      =   176;
% % markers per node
% mx  =   4;
% my  =   4;
% % 2. Set the shape of horizontal layers
% 
% shape_bounds0 = [0, 0, 15000, 3500]; % Entire model boundary [xmin, ymin, xmax, ymax]
% shape_bounds1 = [0, 0, 15000, 500]; % Top rectangle boundary (rigid object) [xmin, ymin, xmax, ymax]
% shape_bounds2 = [0, 3000, 15000, 3500]; % Bottom rectangle boundary (rigid object) [xmin, ymin, xmax, ymax]
% shape_bounds3 = [0, 2500, 15000, 3000]; % Horizontal layer [xmin, ymin, xmax, ymax]
% 
% shape_bounds = [0, 500, 15000, 2500]; % Rectangle boundary [xmin, ymin, xmax, ymax]
% triangle_points = [10000, 2500; 12500, 1000; 15000, 2500]; % Three vertices of the triangle [x1, y1; x2, y2; x3, y3]
% min_radius = 45; % Minimum radius (for major and minor axes of the ellipse)
% max_radius = 400.0; % Maximum radius (for major and minor axes of the ellipse)
% target_area_ratio = 0.2; % Target area ratio (total area of filled shapes / total area of the shape)
% max_attempts = 10000; % Maximum number of attempts
% 
% % 3. Filled shape options
% shape_type = 'ellipse'; % Options: 'circle', 'ellipse', 

% Calculate the total area of the shape (rectangle area - triangle area)
shape_width = shape_bounds(3) - shape_bounds(1);
shape_height = shape_bounds(4) - shape_bounds(2);
rectangle_area = shape_width * shape_height;
triangle_area = polyarea(triangle_points(:, 1), triangle_points(:, 2)); % Calculate the area of the triangle
shape_area = rectangle_area - triangle_area; % Total area of the shape

% Initialization
shapes = []; % Store generated shapes [x, y, param1, param2, ...]
total_shape_area = 0; % Total area of filled shapes
attempts = 0; % Attempt counter

% Generate random shapes
while total_shape_area < target_area_ratio * shape_area && attempts < max_attempts
    % Generate random shape
    geometry_x = shape_bounds(1) + (shape_bounds(3) - shape_bounds(1)) * rand();
    geometry_y = shape_bounds(2)  - max_radius + (shape_bounds(4) - shape_bounds(2) +max_radius  ) * rand();
    
    switch shape_type
        case 'circle'
            r = min_radius + (max_radius - min_radius) * rand();
            geometry_params = [r];
            geometry_area = pi * r^2;
        case 'ellipse'
            ellipse_a = min_radius + (max_radius - min_radius) * rand(); % Major axis
            ellipse_b = min_radius + (max_radius - min_radius) * rand(); % Minor axis
            ellipse_theta = pi/12 * rand()-pi/12 * rand(); % Rotation angle   15以内
            geometry_params = [ellipse_a, ellipse_b, ellipse_theta];
            geometry_area = pi * ellipse_a * ellipse_b;

        otherwise
            error('Unknown shape type');
    end
    
    % Check if the shape is within the rectangle and does not overlap with the triangle  
    %这里可以设置椭圆在哪个边界上
    % if geometry_x - max(geometry_params) >= shape_bounds(1) && geometry_x + max(geometry_params) <= shape_bounds(3) && ...
    %    geometry_y - max(geometry_params) >= shape_bounds(2) && geometry_y + max(geometry_params) <= shape_bounds(4)
 if geometry_x - max(geometry_params) >= shape_bounds(1) && geometry_x + max(geometry_params) <= shape_bounds(3) && ...
geometry_y + max(geometry_params) <= shape_bounds(4)
        % Check if the shape overlaps with the triangle
        if ~is_shape_overlapping_triangle(geometry_x, geometry_y, geometry_params, shape_type, triangle_points)
            % Check if it overlaps with existing shapes
            overlap = false;
            for i = 1:size(shapes, 1)
                dist_sq = (geometry_x - shapes(i, 1))^2 + (geometry_y - shapes(i, 2))^2;
                if dist_sq < (max(geometry_params) + max(shapes(i, 3:end)))^2
                    overlap = true;
                    break;
                end
            end
            
            % If no overlap, add to the shape list and update the total area
            if ~overlap
                shapes = [shapes; geometry_x, geometry_y, geometry_params];
                total_shape_area = total_shape_area + geometry_area;
            end
        end
    end
    attempts = attempts + 1;
end

% Output results
fprintf('Number of generated shapes: %d\n', size(shapes, 1));
fprintf('Total area of filled shapes: %.2f\n', total_shape_area);
fprintf('Total area of the shape: %.2f\n', shape_area);
fprintf('Actual area ratio: %.2f\n', total_shape_area / shape_area);

% % Plot the results
% figure;
% 
% hold on;
% % Draw the rectangle boundary
% rectangle('Position', [shape_bounds(1), shape_bounds(2), ...
%                       shape_bounds(3) - shape_bounds(1), shape_bounds(4) - shape_bounds(2)], ...
%           'EdgeColor', 'k', 'LineWidth', 2);
% % Draw the triangle boundary
% patch(triangle_points(:, 1), triangle_points(:, 2), 'k', 'EdgeColor', 'k', 'FaceColor', 'none', 'LineWidth', 2);
% % Draw the filled shapes
% for i = 1:size(shapes, 1)
%     x = shapes(i, 1);
%     y = shapes(i, 2);
%     params = shapes(i, 3:end);
%     switch shape_type
%         case 'circle'
%             r = params(1);
%             rectangle('Position', [x - r, y - r, 2 * r, 2 * r], ...
%                       'Curvature', [1, 1], 'EdgeColor', 'b', 'FaceColor', [0, 0, 1, 0.5]);
%         case 'ellipse'
%             a = params(1);
%             b = params(2);
%             theta = params(3);
%             draw_ellipse(x, y, a, b, theta);
%         case 'rectangle'
%             w = params(1);
%             h = params(2);
%             theta = params(3);
%             draw_rectangle(x, y, w, h, theta);
%         case 'polygon'
%             polygon_points = params;
%             % patch(polygon_points(:, 1), polygon_points(:, 2), 'b', 'EdgeColor', 'b', 'FaceColor', [0, 0, 1, 0.5]);
%     end
% end
% title(['Random Shape Filling (', shape_type, ')']);
% xlabel('X');
% ylabel('Y');
% set(gca, 'YDir', 'reverse')
% hold on
% 4. Check if a point is inside the triangle

grid_size = [(ny-1)*my, (nx-1)*mx];
grid_x = linspace(shape_bounds0(1), shape_bounds0(3), (nx-1)*mx);
grid_y = linspace(shape_bounds0(2), shape_bounds0(4), (ny-1)*my);
[X, Y] = meshgrid(grid_x, grid_y);

% Initialize the grid point status matrix
grid_status = zeros((ny-1)*my, (nx-1)*mx);

% Check if each grid point is inside the generated circle
for i = 1:(ny-1)*my
    for j = 1:(nx-1)*mx
        geometry_px = X(i, j);
        geometry_py = Y(i, j);
         %3 Set upper and lower horizontal boundaries
             if geometry_py <= shape_bounds1(4) || geometry_py > shape_bounds2(2)
            grid_status(i, j) = 2;
             end
        %0 Set the oceanic crust
            if  geometry_py > shape_bounds3(2) && geometry_py <= shape_bounds3(4)
                grid_status(i, j) = 6;
            end
        %4 Set the shape of the subduction channel
        if geometry_px >= shape_bounds(1) && geometry_px <= shape_bounds(3) && ...
           geometry_py >= shape_bounds(2) && geometry_py <= shape_bounds(4)  && ~is_point_in_triangle(geometry_px, geometry_py, triangle_points)
        
                grid_status(i, j) = 3; 
        end
       %1 Set the shape of the block 
        switch shape_type
        case 'circle'
            for k = 1:size(shapes, 1)
            geometry_x = shapes(k, 1);
            geometry_y = shapes(k, 2);
            r = shapes(k, 3);
            if (geometry_px - geometry_x)^2 + (geometry_py - geometry_y)^2 <= r^2
            grid_status(i, j) = 5; %%Here it is best to correspond to the phase
                break;
            end
            end
         case 'ellipse'
            for k = 1:size(shapes, 1)
            geometry_x = shapes(k, 1);
            geometry_y = shapes(k, 2);
            ellipse_a = shapes(k, 3);
            ellipse_b = shapes(k, 4);
            ellipse_theta = shapes(k, 5);
            if is_point_in_ellipse(geometry_px, geometry_py, geometry_x, geometry_y, ellipse_a, ellipse_b, ellipse_theta)
                 if geometry_px >= shape_bounds(1) && geometry_px <= shape_bounds(3) && ...
           geometry_py >= shape_bounds(2) && geometry_py <= shape_bounds(4)  && ~is_point_in_triangle(geometry_px, geometry_py, triangle_points) 
                grid_status(i, j) = 5; % Inside the ellipse
                break;
            end
            end
            end
        end

     %2 Set the shape of the seamount 
             if is_point_in_triangle(geometry_px, geometry_py, triangle_points)
            grid_status(i, j) = 7; % Inside the triangle
             end
    
    end
end


% 5. plot initial model

if plot_initial_model == 1
    figure (1)
    surf(grid_x,grid_y,grid_status,"EdgeColor","none","FaceColor","interp")
    view(2)
    set(gca,'YDir','reverse');
    xlabel('Distance (m)');
    ylabel('Depth (m)');
    axis image
    
end
% output .mat file

save(geometry_name, 'grid_status');


function inside = is_point_in_triangle(px, py, tri_points)
    % Use barycentric coordinates to determine if a point is inside the triangle
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

% Check if a shape overlaps with the triangle
function overlap = is_shape_overlapping_triangle(x, y, params, shape_type, tri_points)
    % Check if the shape overlaps with the triangle based on the shape type
    switch shape_type
        case 'circle'
            r = params(1);
            overlap = is_circle_overlapping_triangle(x, y, r, tri_points);
        case 'ellipse'
            a = params(1); % Major axis
            b = params(2); % Minor axis
            theta = params(3); % Rotation angle
            overlap = is_ellipse_overlapping_triangle(x, y, a, b, theta, tri_points);
       
        otherwise
            error('Unknown shape type');
    end
end

% Check if a circle overlaps with the triangle
function overlap = is_circle_overlapping_triangle(x, y, r, tri_points)
    % Check if the center of the circle is inside the triangle
    if is_point_in_triangle(x, y, tri_points)
        overlap = true;
        return;
    end
    
    % Check if the circle's boundary intersects with the edges of the triangle
    for i = 1:3
        p1 = tri_points(i, :);
        p2 = tri_points(mod(i, 3) + 1, :);
        
        % Calculate the distance from the line segment to the center of the circle
        a = (x - p1(1)) * (p2(1) - p1(1)) + (y - p1(2)) * (p2(2) - p1(2));
        b = (p2(1) - p1(1))^2 + (p2(2) - p1(2))^2;
        t = max(0, min(1, a / b));
        nearest_x = p1(1) + t * (p2(1) - p1(1));
        nearest_y = p1(2) + t * (p2(2) - p1(2));
        dist_sq = (x - nearest_x)^2 + (y - nearest_y)^2;
        
        % If the distance is less than the radius, the circle intersects with the edge
        if dist_sq < r^2
            overlap = true;
            return;
        end
    end
    
    % Check if the vertices of the triangle are inside the circle
    for i = 1:3
        dist_sq = (x - tri_points(i, 1))^2 + (y - tri_points(i, 2))^2;
        if dist_sq < r^2
            overlap = true;
            return;
        end
    end
    
    % If no overlap
    overlap = false;
end

% Check if an ellipse overlaps with the triangle
% Check if the ellipse's boundary intersects with the edges of the triangle
function overlap = is_ellipse_overlapping_triangle(x, y, a, b, theta, tri_points)
    % Transform the ellipse and triangle points to the ellipse's standard coordinate system
    R = [cos(theta), -sin(theta); sin(theta), cos(theta)]; % Rotation matrix
    inv_R = [cos(theta), sin(theta); -sin(theta), cos(theta)]; % Inverse rotation matrix
    
    % Transform the triangle's vertices to the ellipse's standard coordinate system
    tri_points_transformed = (tri_points - [x, y]) * inv_R;
    
    % Check if the triangle's vertices are inside the ellipse
    for i = 1:3
        px = tri_points_transformed(i, 1);
        py = tri_points_transformed(i, 2);
        if (px^2 / a^2) + (py^2 / b^2) < 1
            overlap = true;
            return;
        end
    end
    
    % Check if the ellipse's boundary intersects with the edges of the triangle
    % Iterate through the three edges of the triangle
    for i = 1:3
        p1 = tri_points_transformed(i, :);
        p2 = tri_points_transformed(mod(i, 3) + 1, :);
        
        % Calculate the distance from the line segment to the center of the ellipse
        a2 = a^2;
        b2 = b^2;
        dx = p2(1) - p1(1);
        dy = p2(2) - p1(2);
        A = dx^2 / a2 + dy^2 / b2;
        B = 2 * (p1(1) * dx / a2 + p1(2) * dy / b2);
        C = p1(1)^2 / a2 + p1(2)^2 / b2 - 1;
        
        % Calculate the discriminant
        discriminant = B^2 - 4 * A * C;
        
        % If the discriminant is greater than or equal to 0, the line segment intersects with the ellipse
        if discriminant >= 0
            overlap = true;
            return;
        end
    end
     if is_point_in_triangle(x, y, tri_points)
        overlap = true;
        return;
    end
    
    % If no overlap
    overlap = false;
end

% Draw an ellipse
function draw_ellipse(x, y, a, b, theta)
    t = linspace(0, 2 * pi, 100);
    ellipse_x = a * cos(t);
    ellipse_y = b * sin(t);
    R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
    ellipse_points = [ellipse_x; ellipse_y]' * R;
    patch(x + ellipse_points(:, 1), y + ellipse_points(:, 2), 'b', 'EdgeColor', 'b', 'FaceColor', 'b');
end

% Draw a rectangle
function draw_rectangle(x, y, w, h, theta)
    rect_points = [-w/2, -h/2; w/2, -h/2; w/2, h/2; -w/2, h/2];
    R = [cos(theta), -sin(theta); sin(theta), cos(theta)];
    rect_points = rect_points * R;
    patch(x + rect_points(:, 1), y + rect_points(:, 2), 'b', 'EdgeColor', 'b', 'FaceColor', 'b');
end

function inside = is_point_in_ellipse(px, py, x, y, a, b, theta)
    % Transform the point to the ellipse's standard coordinate system
    R = [cos(theta), -sin(theta); sin(theta), cos(theta)]; % Rotation matrix
    inv_R = [cos(theta), sin(theta); -sin(theta), cos(theta)]; % Inverse rotation matrix
    
    % Transform the point to the ellipse's standard coordinate system
    point_transformed = ([px, py] - [x, y]) * inv_R;
    
    % Check if the point is inside the ellipse
    inside = (point_transformed(1)^2 / a^2) + (point_transformed(2)^2 / b^2) <= 1;
end