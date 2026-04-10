function forest_simulator_gui
    dt = 0.1; 
    t_vec = 0:dt:11; 
    history_R = []; 
    history_beta = [];
    treeX = [];
    treeY = [];

    fig = uifigure('Name', 'Принцип Эйлера с хетмапом', 'Position', [100 100 650 550]);
    gl = uigridlayout(fig, [3, 1]);
    gl.RowHeight = {'1x', 35, 30};

    ax = uiaxes(gl);
    ax.YDir = 'normal'; 
    hold(ax, 'on'); grid(ax, 'on');
    axis(ax, 'equal'); xlim(ax, [1 100]); ylim(ax, [1 100]);
    
    bgImage = imagesc(ax, zeros(100)); 
    colormap(ax, bone); 
    bgImage.HitTest = 'off'; 
    
    crownPlot = gobjects(0);
    trunkPlot = scatter(ax, [], [], 18, 'filled', ...
        'MarkerFaceColor', [0.33 0.19 0.07], 'MarkerEdgeColor', 'k');

    ctrlPanel = uigridlayout(gl, [1, 3]);
    ctrlPanel.Padding = [0 0 0 0];
    ctrlPanel.ColumnWidth = {120, 60, '1x'};

    uilabel(ctrlPanel, 'Text', 'Число деревьев:', 'HorizontalAlignment', 'right');
    numTreesField = uieditfield(ctrlPanel, 'numeric', 'Value', 30, 'Limits', [1 500], 'RoundFractionalValues', 'on');
    btn = uibutton(ctrlPanel, 'Text', 'Пересоздать лес', 'ButtonPushedFcn', @spawn);

    sld = uislider(gl, 'Limits', [t_vec(1) t_vec(end)], 'Value', t_vec(1), ...
        'ValueChangingFcn', @(s,e) draw_frame(e.Value));

    
    function spawn(~, ~)
        N = numTreesField.Value; 
        mc_points = min(800, max(300, round(10 * N)));
        
        terrainMap = imgaussfilt(rand(100), 3) * 5; 
        bgImage.CData = terrainMap; 

        X = rand(N, 1) * 100;
        Y = rand(N, 1) * 100;
        mcX = rand(mc_points, 1) * 100;
        mcY = rand(mc_points, 1) * 100;
        
        fertility = interp2(1:100, 1:100, terrainMap, X, Y, 'nearest') + 1;

        b = 0.02 + rand(N, 1) * 0.08; 
        a = fertility .* (1 + rand(N, 1) * 3);
        c = 0.15 + 0.25 * rand(N, 1);
        R_init = 1 + rand(N, 1) * 4; 

        history_R = zeros(N, length(t_vec));
        history_beta = zeros(1, length(t_vec));
        current_R = R_init;
        history_R(:, 1) = current_R;
        history_beta(1) = estimate_beta(X, Y, current_R, mcX, mcY);

        for i = 2:length(t_vec)
            beta_t = history_beta(i - 1);
            dR_dt = beta_t .* a - b .* (current_R.^2) - c;
            current_R = current_R + dR_dt * dt;
            current_R(current_R < 0) = 0;
            history_R(:, i) = current_R;
            history_beta(i) = estimate_beta(X, Y, current_R, mcX, mcY);
        end
        
        treeX = X;
        treeY = Y;
        crownPlot = recreate_crowns(N);
        trunkPlot.XData = treeX;
        trunkPlot.YData = treeY;
        sld.Value = t_vec(1);
        draw_frame(t_vec(1));
    end

    function draw_frame(t_val)
        if isempty(history_R) || isempty(treeX), return; end
        
        [~, idx] = min(abs(t_vec - t_val)); 
        current_R = history_R(:, idx);
        beta_t = history_beta(idx);
        
        alive_mask = current_R > 0;
        num_alive = sum(alive_mask);
        
        if num_alive > 0
            avg_size = mean(current_R(alive_mask));
        else
            avg_size = 0;
        end
        
        update_crowns(crownPlot, treeX, treeY, current_R);
        title(ax, sprintf('Время: %.1f | beta(t): %.3f | Живых деревьев: %d | Ср. размер: %.1f', ...
              t_vec(idx), beta_t, num_alive, avg_size));
    end

    function patchHandles = recreate_crowns(numTrees)
        if ~isempty(crownPlot)
            delete(crownPlot(ishandle(crownPlot)));
        end
        patchHandles = gobjects(numTrees, 1);
        for k = 1:numTrees
            patchHandles(k) = patch(ax, NaN, NaN, [34 139 34] / 255, ...
                'FaceAlpha', 0.22, 'EdgeColor', [0 0 0], ...
                'LineWidth', 0.75, 'HitTest', 'off');
        end
    end

    function update_crowns(patchHandles, X, Y, radii)
        theta = linspace(0, 2 * pi, 40);
        cos_theta = cos(theta);
        sin_theta = sin(theta);

        for k = 1:numel(patchHandles)
            radius = radii(k);
            if radius <= 0
                patchHandles(k).XData = NaN;
                patchHandles(k).YData = NaN;
            else
                patchHandles(k).XData = X(k) + radius .* cos_theta;
                patchHandles(k).YData = Y(k) + radius .* sin_theta;
            end
        end
    end

    function beta_t = estimate_beta(X, Y, radii, sampleX, sampleY)
        alive_mask = radii > 0;
        if ~any(alive_mask)
            beta_t = 0;
            return;
        end

        X_live = X(alive_mask);
        Y_live = Y(alive_mask);
        radii_live = radii(alive_mask);

        dx = sampleX - X_live.';
        dy = sampleY - Y_live.';
        cover_counts = sum(dx.^2 + dy.^2 <= radii_live.'.^2, 2);
        cover_counts = cover_counts(cover_counts > 0);

        if isempty(cover_counts)
            beta_t = 1;
            return;
        end

        max_overlap = max(cover_counts);
        overlap_hist = accumarray(cover_counts, 1, [max_overlap, 1]);
        p_i = overlap_hist / sum(overlap_hist);
        beta_t = sum(p_i ./ (1:max_overlap)');
    end

    spawn(); 
end
