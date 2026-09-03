%% 3D Conservative Stokes / Marker in cell / plastic iterations
% VisoElastoPlasic approach
% by Jonas, March/April 2012

% ==================================set model geometry ======================
clear all 
cd /Users/scsio/Desktop/runmodel/2025-6-2/TY3
% put on the geometry name
geometry_name = 'TY3.mat';
outputfilename = 'test+grave';
% calculate the Energy dissipation rate 
% 1. set number of model nodes
% Length of model
Lx   =  15e3;
Ly   =  2.5e3;
% number of nodes 
nx      =   751;
ny      =   151;

% markers per node
mx  =   4;
my  =   4;
% 2. Set the shape of horizontal layers

shape_bounds0 = [0, 0, Lx, Ly]; % Entire model boundary [xmin, ymin, xmax, ymax]
shape_bounds1 = [-100, 0, 15000, -500]; % Top rectangle boundary (rigid object) [xmin, ymin, xmax, ymax]
shape_bounds2 = [-100, 0, 15000, -500]; % Bottom rectangle boundary (rigid object) [xmin, ymin, xmax, ymax]
shape_bounds3 = [0, 2600, 15000, 3000]; % Horizontal layer [xmin, ymin, xmax, ymax]

shape_bounds = [0, 000, 15000, 2500]; % Rectangle boundary [xmin, ymin, xmax, ymax]
triangle_points = [10000, 2500; 12500, 1500; 15000, 2500]; % Three vertices of the triangle [x1, y1; x2, y2; x3, y3]
min_radius = 50; % Minimum radius (for major and minor axes of the ellipse)
max_radius = 250.0; % Maximum radius (for major and minor axes of the ellipse)
target_area_ratio = 0.27; % Target area ratio (total area of filled shapes / total area of the shape)
max_attempts = 5000; % Maximum number of attempts
% 3. Filled shape options
shape_type = 'circle'; % Options: 'circle', 'ellipse', 


% Load geometrty or generate a new geometry

if ~exist(char(geometry_name))
    generate_geometry;
else 
    load (geometry_name, 'grid_status')
end

%===========================================================================
% ======================================start to run model ================= 


% addpath('SOURCE_FILES')                        % FUNCTIONS
mkdir('outputfilename')

create_output       = 50;
create_breakpoint   = 200;

brutus              = 1;    % 1 if you run it on cluster (without plotting every timestep)
Temperature         = 0;    % 0: no temperature | 1: Normal temperature input | 2: Fixed temperture
Powerlaw            = 0; 
Diffusion_creep     = 0;
Surface_diffusion   = 0;
Beam_function       = 0;    % 1: beam function of elastic bending at the bottom. Requires material below the bottom and no boundary velocities
delta_prograd       = 0;    % 1: delta progradation on the left side of the model

if brutus == 0
    cd /Users/scsio/Desktop/Barcelona/2_two-phase-shear-code/COLORMAPS
        mat = dir('*.mat');
        for i=1:length(mat)
            load(mat(i).name);
        end    
    cd /Users/scsio/Desktop/Barcelona
end

% Length of model
% Lx   =  15e3;
% Ly   =  3.5e3;

%number of nodes
% nx      =   751;
% ny      =   176;
p_node  =   376;   % between 3 and nx-2

%markers per node
% mx  =   4;
% my  =   4;

        % Phase    Visc       EModul    Dens     Phi     PhiW      Coh         CohW      lamb      Hr       Ta      Tb       cp      Temp       kk       n       Q      DifCreep    grains      m      Qd
ROCKS= [    1      1.e18       1e10        1       0       1       1e20        1e20        0        0        0       0      3e6       273      200       1       0             0        0       0       0   ;   % AIR
            2      1.e24       1e10     2700      35      35       1e20        1e20      0.8     2e-6    2e-5   45e-13      1e3       273      2.5      1.0  220e3     1.5849e18     2e-2      -2   220e3   ;   % Overriding plate
            3      1.e24       1e10     2500      20      20       20e6        20e6      0.8     2e-6    2e-5   45e-13      1e3       273      2.5      1.0  220e3     1.5849e18     2e-2      -2   220e3   ;   % Weak sediment
            4      1.e24       1e10     2500      20      20       20e6        20e6      0.8     2e-6    2e-5   45e-13      1e3       273      2.5      1.0  220e3     1.5849e18     2e-2      -2   220e3   ;   % Weak sediment (not use)
            5      1.e24       1e10     3000      36      36       40e6        40e6      0.8     2e-6    2e-5   45e-13      1e3       273      2.5      1.0  220e3     1.5849e18     2e-2      -2   220e3   ;   % Block
            6      1.e24       1e10     3000      36      36       40e6        40e6      0.80    2e-6    2e-5   45e-13      1e3       273      2.5      1.0  125e3     1.5849e18     2e-2      -2   220e3   ;   % Oceanic crust
            7      1.e24       1e10     3000      36      36       40e6        40e6      0.80    2e-6    2e-5   45e-13      1e3       273      2.5      1.0  125e3     1.5849e18     2e-2      -2   220e3   ];  % Seamount
% ROCKS= [    1      1e18        1e10        1       0       1       1e20        1e20        0        0        0       0      3e6       273      200       1       0             0        0       0       0   ;   % AIR
%             2      1e24        1e10     2700      35      35       1e20        1e20      0.0     2e-6    2e-5   45e-13      1e3       273      2.5      1.0  220e3     1.5849e18     2e-2      -2   220e3   ;   % Overriding plate
%             3      1e23        1e10     2700      25       5        5e6         1e6      0.0     2e-6    2e-5   45e-13      1e3       273      2.5      1.0  220e3     1.5849e18     2e-2      -2   220e3   ;   % Weak sediment
%             4      1e23        1e10     2700      25       5        5e6         1e6      0.0     2e-6    2e-5   45e-13      1e3       273      2.5      1.0  220e3     1.5849e18     2e-2      -2   220e3   ;   % Weak sediment
%             5      1e24        1e10     2700      30       5       20e6         5e6      0.0     2e-6    2e-5   45e-13      1e3       273      2.5      1.0  220e3     1.5849e18     2e-2      -2   220e3   ;   % Block
%             6      1e24        1e10     2700      30       5       40e6         5e6      0.00    2e-6    2e-5   45e-13      1e3       273      2.5      1.0  125e3     1.5849e18     2e-2      -2   220e3   ;   % Oceanic crust
%             7      1e24        1e10     2700      30       5       40e6         5e6      0.00    2e-6    2e-5   45e-13      1e3       273      2.5      1.0  125e3     1.5849e18     2e-2      -2   220e3   ];  % Seamount           
% 
Phase   =   ROCKS(:,1)';
eta     =   ROCKS(:,2)';
mu      =   ROCKS(:,3)';
rho     =   ROCKS(:,4)';
phi     =   ROCKS(:,5)';
phi_w   =   ROCKS(:,6)';
C       =   ROCKS(:,7)';
C_w     =   ROCKS(:,8)';
lambda  =   ROCKS(:,9)';
if Temperature == 1
    hr  =   ROCKS(:,10)';
    ta  =   ROCKS(:,11)';
    tb  =   ROCKS(:,12)';
    cp  =   ROCKS(:,13)';
    T   =   ROCKS(:,14)';
    kk  =   ROCKS(:,15)';
end
if Powerlaw == 1
    n   =   ROCKS(:,16);
    Q   =   ROCKS(:,17);
end
if Diffusion_creep == 1
    dCr =   ROCKS(:,18);
    Gr  =   ROCKS(:,19);    
    m   =   ROCKS(:,20);
    Qd  =   ROCKS(:,21);
end
    
variable_lambda=0;      % 1: initial lambda; 2: equalized whole column; 3: equalized top 4 km
lambda_bottom=0.95;
lambda_increase=0.00;
OH_const = 50e6;
Lith = 100e3;

Shear_zone_depth    =   10e3;
p_init              =   Shear_zone_depth*9.81*2700; % Pressure at depth of Shear_zone_depth


% % Geometry      Phase       x-min       x-max       y-min       y-max
% SETUP   =   [   2           0           Lx          0           500      ;
%                 3           0           Lx          500         2500     ;
%                 6           0           Lx          2500        3000     ;
%                 2           0           Lx          3000        3500     ];
% 
% %  Block geometry

% Plastic weakeing thresholds
w_1 = 0.1;
w_2 = 1.0;

% Parameters
gravity_y       =   9.81;
gravity_x       =   0.0;
SecYear         =   3600*24*365.25;
% p_init          =   1e5;

% Surface process
SedimentationStyle  =   1;          % 1 = sed and ero || 2 = only sed || 3 = only ero || 4 = linear below sealevel
SurfaceCoeff        =  [1e-6];   % Coefficient for [SEDIMENTATION EROSION] FOR DIFFERENT SURFACE PROCESSES, OTHERWISE ONLY ONE COEFFICIENT
SurfaceBC_left      =   -1;       % For free slip: -1
SurfaceBC_right     =   -1;       % For free slip: -1
Surface_dt          =   1;         % makes surface process every xx timestep
time_old            =   0;
SediMarker          =  [ ];       % Marker type for sedimentation
ErosMarker          =   1;          % Marker type for erosion
SedChange           =   2e6;        % Marker change for sedimentation in years
WaterLevel          =   0;          % If WaterLevel == 0 it is switched off !!
SediRate            =   0;      % Linear sedimentation rate in m/yr
surface_nodes       =   5;          % Times x nodes along surface
surface_init        =   10000;
surface_x           =   [0:(Lx/(nx-1))/surface_nodes:Lx];
surface_y           =   [surface_init*ones(1,length(surface_x))];
surface_smoother    =   3;


% Cutoff viscosities
eta_max = 1e24;
eta_min = 1e16;
% eta_bingham = 5e18;

if Temperature==1
    % Temperature boundary conditions
    A_thick     =   10e3; % Thickness of sticky-air
    C_thick     =   33e3; % Thickness of Crust
    L_thick     =   Lith; % Thickness of Lithosphere
    Moho_temp   =   660;  % Temperature at Moho in ?C
    L_A_temp    =   1270+Lith/2000; % Temperature at Lithosphere/Asthenosphere boundary in ?C
    M_grad      =   0.5;  % Temperature gradient in Mantle (background)
    Pert_beg    =   490e3;
    Pert_end    =   510e3;
    Pert_add    =   0e3; % km difference for Lithosphere/Asthenosphere depth
    top_T       =   273;    % temperature in case of shear model (in Kelvin)
    Ext_T       =   0.996;
    if Ext_T == 1
        bottom_T    =   L_A_temp+273+M_grad*(Ly-A_thick-L_thick)/1e3;
    elseif Ext_T == 2
        bottom_T    =   top_T;
    else
        bottom_T    =   ((L_A_temp+273)+M_grad*(Ly-L_thick-A_thick)/1000+(Ly/(ny-1))/1000*M_grad/2) - Ext_T*((L_A_temp+273)+M_grad*(Ly-L_thick-A_thick)/1000-(Ly/(ny-1))/1000*M_grad/2);
    end
    shear_heat  =   0.99;
    ra_heat     =   1;
    adiab_heat  =   1;
    TPdep_dens  =   0;
end

% Velocity boundary conditions

%   L T T T T T T T T T T T RR      T T T T T T T T T T T T T   
%   L                       RR      L                       R
%   L      x-velocity       RR      L      y-velocity       R
%   L                       RR      L                       R
%   L                       RR      B B B B B B B B B B B B B
%   L B B B B B B B B B B B RR      B B B B B B B B B B B B B


BC_left_init     =  0;  % no need if mirrored
BC_right_init    =  0;  % no need if mirrored
BC_top_init      =  0.005;  % meter per year
BC_bottom_init   = -0.005;  % meter per year
bound            = {'freeslip','noslip','velocity','external','mixed','mirror'};
top_BC           = bound(3);
bottom_BC        = bound(3);
left_BC          = bound(6);
right_BC         = bound(6);

% Inversion
inversion = [100e6 100e6 150e6 150e6];     % Time in Ma for velocity inversion

% Incoming marker type
mark_top    = 1;
mark_bottom = 17;

%=============================================
% Initialize matrices and coordinates
initialize_beg;
%=============================================

% Initial marker pattern
% 如果要做交错网格，那么必须有三个材料是一样的
% 如果是水平或者垂向条纹，那么只需要有两个材料是一样的
pattern_marker  =   [  ];     % Types of markers with pattern (check marker phases !!!!)
pattern_type    =   {'horizontal','vertical','kaki'};   % Stripes or kaki
pattern_type    =   pattern_type(3);
pattern_xdim    =   500;    % thickness of vertical stripes
pattern_ydim    =   500;    % thickness of horizontal stripes

%=============================================
% Initialize phase and temperature distribution of marker 
marker_distribution;
%=============================================

% Initial time and iteration setup
time        = 0;
t_beg       = 1;
dt_value    = 0.25;          % threshold value for maximal timestep, 0.1 = 10% movement of dx or dy
Ddt         = 500*SecYear;  % Initial timestep to pre-stress
short_dt    = 500*SecYear;  % Short initial timestep
dt_max      = 500*SecYear;  % Timestep
n_short_dt  = 1;            % Number of short initial timesteps
miniter     = 1;             % minimal number of iterations
maxiter     = 1;             % maximal number of iterations
error       = 1;             % 1 = Error 1 (average nodal velocity change); 2 = Error 2 (largest nodal velocity change)
vel_res     = 1e-14;         % sum(velocity) change fot iter break
strain_rate_smoother = 0.87;
Timelong    = 1.2*1e4;          % times steps

tao_eff_total = zeros(1,Timelong);
napp          = zeros(1,Timelong);

% Load breakpoint file if necessary
if exist(char('Breakpoint.mat'))
    load Breakpoint.mat
    t_beg    = timestep+1;
end

%=========================== START TIME LOOP ==========================
%======================================================================

for timestep = t_beg:Timelong
    tic

%     if timestep>100
%         left_BC          = bound(1);
%         right_BC         = bound(1);
%     end
    
    dt=dt_max;
    if timestep <= n_short_dt
        dt = short_dt;  
    end
    
    velocity_inversion;
    
    for niter = 1:maxiter

        fprintf('Timestep: %d\n', timestep);
        fprintf('Iteration: %d\n', niter);
        
        %=============================================
        % Reload old values and initialize matrices
        initialize_iter;
        %=============================================
        
        %=============================================
        % Calculate power-law and brittle viscosities
        viscosity_calculation_wet;
        %=============================================
        
        %=============================================
        % Fill nodal values from marker information
        marker_to_nodes; % dispatched loops, better for desktop
        toc, fprintf('for updating nodal values!\n'); 
        %=============================================   
        
        if Temperature == 1            
            % Boundary conditions to interpolated T
            % Upper BC
            Temp((ny+1)+1:(ny+1):(nx-1)*(ny+1)+1)   =   top_T*2 - Temp((ny+1)+2:(ny+1):(nx-1)*(ny+1)+2);
            % Lower BC
            if Ext_T == 1 || Ext_T == 2
                Temp(2*(ny+1):(ny+1):(nx)*(ny+1))       =   bottom_T'*2 - Temp(2*(ny)+1:(ny+1):(nx)*(ny+1)-1);
            else
                Temp(2*(ny+1):(ny+1):(nx)*(ny+1))       =   bottom_T + Ext_T*Temp(2*(ny)+1:(ny+1):(nx)*(ny+1)-1);
            end
            % Left BC
            Temp(1:ny+1)                            =   Temp(ny+2:2*(ny+1));
            % Right BC
            Temp(nx*(ny+1)+1:(nx+1)*(ny+1))         =   Temp((nx-1)*(ny+1)+1:(nx)*(ny+1));
        end
        
        %=====================================================
        
        %=============================================
        % Fill and solve matrix for stokes
        stokes_direct_solver;
        toc, fprintf('for solving the matrix!\n')
        %=============================================
        
        Vx    =   S(1:(ny+1)*(nx+1));
        Vy    =   S(1+(ny+1)*(nx+1):2*(ny+1)*(nx+1));
        P     =   S(2*(ny+1)*(nx+1)+1:end).*kcont;
        
        Vx2d    =   reshape(Vx,ny+1,nx+1);
        Vy2d    =   reshape(Vy,ny+1,nx+1);
        P2d     =   reshape(P,ny+1,nx+1);
                
        %======================================================================
        % redistributing S
        
        %   1--6--11--16
        %   |  |  |    |
        %   2--7--12--17
        %   |  |  |    |
        %   3--8--13--18
        %   |  |  |    |
        %   4--9--14--19
        %   |  |  |    |
        %   5-10--15--20
        
        Vx2d_s   =   (Vx2d(1:end-1,1:end-1)+Vx2d(2:end,1:end-1))./2;
        Vy2d_s   =   (Vy2d(1:end-1,1:end-1)+Vy2d(1:end-1,2:end))./2;
        P2d_p    =   P2d;
        %     T2dn     =   T2d;
        
        % define optimal timestep
        Ddt = dt;
        
        Vx_max  =   max(max(abs(Vx2d_s)));
        Vy_max  =   max(max(abs(Vy2d_s)));
        
        if dt_value*1/(Vx_max/dx + Vy_max/dy) < Ddt
            Ddt  =   dt_value*1/(Vx_max/dx + Vy_max/dy);
        end
                
        %=============================================
        % Calculating strain rates and stresses
        strain_rate_stress_calculation;
        toc, fprintf('for strain/stress calculation and interpolation to markers!\n');
             fprintf('========= Ddt = %d years =============================\n',Ddt/SecYear);
        %=============================================
        
        fprintf('========= Min Pressure = %d MPa ===========================\n',min(P)/1e6);
        fprintf('========= Max Pressure = %d MPa ===========================\n',max(P)/1e6);
   
        %=============================================
        % Calculating strain rates and stresses
        vel_res_calculation;
        if timestep>1
            fprintf('========= VELOCITY ERROR %d = %d =========\n\n',error,iterations(error,niter+maxiter*(timestep-1)));
            fprintf('========= Pressure change on node = %d =========\n\n',dP_node(timestep));
        end
        %=============================================

        % Plotting if running on desktop
        if brutus==0 && timestep>1
            E2nd_s_2d   =   reshape(E2nd_s,ny+1,nx+1);
            eta_s_2d    =   reshape(eta_s,ny+1,nx+1);
            strain_2d   =   reshape(strain,ny+1,nx+1);
            strainv_2d   =   reshape(strainv,ny+1,nx+1);
            lambda_s_2d   =   reshape(lambda_s,ny+1,nx+1);
            
            figure(1), clf
            colormap jet
            
            subplot(231)
            pcolor(x_Vx(1:end-1),y_Vy(1:end-1),log10(E2nd_s_2d(1:end-1,1:end-1)))%, caxis([-14 -10])
            shading interp
            colorbar
            axis image, axis ij
            title('E2nd [1/s]')
            
            subplot(232)
            pcolor(x_Vx(1:end-1),y_Vy(1:end-1),log10(eta_s_2d(1:end-1,1:end-1))), caxis(log10([eta_min eta_max]))
            shading interp
            colorbar
            axis image, axis ij
            title(['\eta_{s} [Pa.s] ',    num2str(Ddt/SecYear)])
            drawnow

            subplot(233)
            pcolor(x_Vx(1:end-1),y_Vy(1:end-1),(strain_2d(1:end-1,1:end-1)))
            shading interp
            colorbar
            axis image, axis ij
            title(['Strain [-] ',    num2str(Ddt/SecYear)])
            drawnow
            
            subplot(234)
            pcolor(x_Vx(1:end-1),y_Vy(1:end-1),(T2nd_s_2d(1:end-1,1:end-1)))
            shading interp
            colorbar
            axis image, axis ij
            title(['\tau_{s} [Pa] ',    num2str(Ddt/SecYear)])
            drawnow

            subplot(235)
            pcolor(x_Vx(1:end-1),y_Vy(1:end-1),Vx2d_s*SecYear)
            shading interp
            colorbar
            axis image, axis ij
            title(['V_{x} [m/yr] ',    num2str(Ddt/SecYear)])
            drawnow

            subplot(236)
            pcolor(x_Vx(1:end-1),y_Vy(1:end-1),Vy2d_s*SecYear)
            shading interp
            colorbar
            axis image, axis ij
            title(['V_{y} [m/yr] ',    num2str(Ddt/SecYear)])
            drawnow

            
            figure(444)
            subplot(211), semilogy((niter-1)/maxiter+(timestep-1),iterations(1,niter+maxiter*(timestep-1)),'ko'), hold on
            title('Error 1: with sticky-air')
            subplot(212), semilogy((niter-1)/maxiter+(timestep-1),iterations(2,niter+maxiter*(timestep-1)),'ko'), hold on
            title('Error 2: with sticky-air')
        end
        
        % Exiting the iteration loop
        if (niter>=miniter && iterations(error,niter+maxiter*(timestep-1))<vel_res) || timestep==1
            break;
        end
    end

    %==========================================================================
    dt = Ddt;
    
    % Calculating accumulated plastic/viscous strain and grain size
    Strain_GrainSize_GSE;
    %==========================================================================

    %=============================================
    % Calculating temperature
    subgrid_diffusion_stresses;
    stress_rotation;
    % Average deviatoric stress
    Sigma_d(1,timestep)     =   sum((Txxm.^2 + Txym.^2).^0.5)./length(T2ndm);
    Visc_d(1,timestep)      =   sum(eta_effm)./length(eta_effm);
    % ind=find((Im==2 | Im==3) & ind_plast==0);
    % D_qtz_d(1,timestep)     =   sum(dm(ind))/length(ind);
    % def_mode_qtz_d(1,timestep)     =   sum(def_modem(ind))/length(ind);
    % ind=find((Im==4 | Im==5) & ind_plast==0);
    % D_plg_d(1,timestep)     =   sum(dm(ind))/length(ind);
    % def_mode_plg_d(1,timestep)     =   sum(def_modem(ind))/length(ind);
    %=============================================
    
    %=============================================
    % Calculating temperature
    if Temperature == 1
        temperature_direct_solver;
        toc, fprintf('for temperature calculation!\n');
    end
    %=============================================


    %=============================================
    % Move markers
    move_marker;
%     move_surface;
    if Beam_function == 1
        beam_function;
    end

    toc, fprintf('for moving makers!\n');
    %=============================================

    time = time + dt;

    %======================================================================
    % Visualization begin
    %======================================================================


    if brutus == 0  figure(3), clf
        
        for i=1:20
            Phase1  =   find(Im == i);
            marksize = 5;
            hold on
            plot(xm(Phase1),ym(Phase1),'.','Color',Colormaps(i,:),'MarkerSize',marksize)
        end
      
        
%         plot(surface_x,surface_y,'r'), hold on
        
        axis image, axis ij
        title(['Time: ',num2str((time)/SecYear/1e6),' Ma'])
%         plot(x2d_b,y2d_b,'k',x2d_b',y2d_b','k')
%         quiver(x2d_b,y2d_b,Vx2db,Vy2db,'r','LineWidth',1.5)
        E2nd_s_2d   =   reshape(E2nd_s,ny+1,nx+1);
        eta_s_2d    =   reshape(eta_s,ny+1,nx+1);
        T2nd_s_2d   =   reshape(T2nd_s,ny+1,nx+1);
                
        hold off
                
%         figure(8)
%         plot(surface_x,surface_y,'b'), hold off
%         axis ij
        
        figure(4), clf
        colormap jet
        
        subplot(311)
        pcolor(x_Vx(1:end-1),y_Vy(1:end-1),log10(E2nd_s_2d(1:end-1,1:end-1)))%, caxis([-14 -10])
        shading interp
        colorbar
        axis image, axis ij
        title('E2nd ')
        
        subplot(312)
        pcolor(x_Vx(1:end-1),y_Vy(1:end-1),log10(eta_s_2d(1:end-1,1:end-1))), caxis(log10([eta_min eta_max]))
        shading interp
        colorbar
        axis image, axis ij
        title(['\eta_{s}   ',    num2str(dt/SecYear)])
        
        subplot(313)
        pcolor(x_Vx(1:end-1),y_Vy(1:end-1),(T2nd_s_2d(1:end-1,1:end-1)))
        shading interp
        colorbar
        axis image, axis ij
        title(['T2nd'])
        drawnow
    end

    %==========================================================================
    % Visualization end
    %==========================================================================

    %=============================================
    % Delete markers out of grid
%     outgrid_marker;
    %=============================================

    %=============================================
    % New markers from sides
%     incoming_marker;
%     toc, fprintf('for outgoing/incoming markers!\n');
    %=============================================
    
    %=============================================
    % Surface process
    if  Surface_diffusion == 1
%         if WaterLevel > 0            
%             if SedimentationStyle == 4
%                 ind=find(Im==2 & ym>WaterLevel);
%                 if round(time/SecYear/SedChange)<time/SecYear/SedChange && length(SediMarker)==2
%                     ii=1;
%                 else
%                     ii=2;
%                 end
%                 Im(ind) = SediMarker(ii);
%                 
%                 ind=surface_y>WaterLevel;
%                 surface_y(ind)=WaterLevel;
%             end
%             if SedimentationStyle == 5
%                 pf_x1=Lx/2-time/SecYear*0.0025;
%                 pf_x2=Lx/2+time/SecYear*0.0025;
%                 
%                 ind=find(-(surface_x-pf_x1)*tand(30)+WaterLevel<surface_y & surface_x<=Lx/2);
%                 surface_y(ind)=-(surface_x(ind)-pf_x1)*tand(30)+WaterLevel;
%                 ind=find((surface_x-pf_x2)*tand(30)+WaterLevel<surface_y & surface_x>Lx/2);
%                 surface_y(ind)=(surface_x(ind)-pf_x2)*tand(30)+WaterLevel;
%                 ind=surface_y<WaterLevel;
%                 surface_y(ind)=WaterLevel;
%             end        
%         end
        
        surface_calculation;
        toc, fprintf('for surface process!\n');
    end
    %=============================================
    work_ratem  = (Txxm.^2)./eta_effm + (Txym.^2)./eta_effm; % Energy dissipation of material deformation
    workm       = workm + work_ratem.*dt;                    
    
    Bulk_strain_rate        = abs(BC_top_init*2/SecYear)/Ly;               %  Bulk strain rate
    H                       = work_ratem.*Lx.*Ly/marknum;%the mechanical energy dissipation per mark
    epsilon_II_vp           = Bulk_strain_rate.*Lx.*Ly; %visco-plastic strain 
    tao_effm                = H./2./epsilon_II_vp;      %effective strength
    
    tao_eff_total(1,timestep)           = sum(tao_effm);
    napp(1,timestep)                    = sum(tao_effm)/Bulk_strain_rate;%Apparent long-term viscosity
    %=============Energy dissipation==========================
    




    fprintf('dt   = %d years\n', dt/SecYear)
    fprintf('Time = %d years\n\n', time/SecYear)

    toc, fprintf('for complete timestep\n===============\nMarknum: %d\n===============\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n', marknum);    

    %======================== SAVE OUTPUT FILE ============================
    if mod(timestep,create_output)==0 || timestep==2 || timestep==3
        
        fname = ['Shearing_',num2str(1e6+timestep),'.mat'];
        cd('outputfilename/')
        % save([char(fname)]   ,'Vx2d_s','Vy2d_s','E2nd_s','T2nd_s','xm','Txx','Txy',...
        %     'ym','Im','eta_s','P2d','Lx','Ly','strain','strainv','lambda_s','rho_s','Sigma_d','Visc_d',...
        %     'nx','ny','time','dt','SecYear','x','y','iterations','Pm','work');
        % cd ..
        save([char(fname)]   , 'E2nd_s','T2nd_s','xm','Txx','Txy',...
    'ym','Im','eta_s','P2d','Lx','Ly','strain','strainv','lambda_s','rho_s','Sigma_d','Visc_d',...
    'nx','ny','time','dt','SecYear','x','y','iterations',...
    'Bulk_strain_rate','napp','tao_eff_total');
        cd ..
    end

    % Save breakpoint file
    if mod(timestep,create_breakpoint)==0
        fname = ['Breakpoint1.mat'];
        save(char(fname))
%         break
        movefile('Breakpoint1.mat','Breakpoint.mat');
    end
end
