function forest_simulator_gui
    dt = 0.1; 
    t_vec = 0:dt:101; 
    history_R = []; 

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
    
    treePlot = scatter(ax, [], [], 'filled', 'MarkerFaceColor', '#228B22', 'MarkerEdgeColor', 'k');

    ctrlPanel = uigridlayout(gl, [1, 3]);
    ctrlPanel.Padding = [0 0 0 0];
    ctrlPanel.ColumnWidth = {120, 60, '1x'};

    uilabel(ctrlPanel, 'Text', 'Число деревьев:', 'HorizontalAlignment', 'right');
    numTreesField = uieditfield(ctrlPanel, 'numeric', 'Value', 30, 'Limits', [1 500], 'RoundFractionalValues', 'on');
    btn = uibutton(ctrlPanel, 'Text', 'Пересоздать лес', 'ButtonPushedFcn', @spawn);

    sld = uislider(gl, 'Limits', [0 10], 'Value', 0, 'ValueChangingFcn', @(s,e) draw_frame(e.Value));

    
    function spawn(~, ~)
        N = numTreesField.Value; 
        
        terrainMap = imgaussfilt(rand(100), 3) * 5; 
        bgImage.CData = terrainMap; 

        X = rand(N, 1) * 100;
        Y = rand(N, 1) * 100;
        
        fertility = interp2(1:100, 1:100, terrainMap, X, Y, 'nearest') + 1;

        b = 0.02 + rand(N, 1) * 0.08; 
        a = fertility .* (1 + rand(N, 1) * 3);
        R_init = 1 + rand(N, 1) * 4; 

        history_R = zeros(N, length(t_vec));
        current_R = R_init;
        history_R(:, 1) = current_R;

        for i = 2:length(t_vec)
            dR_dt = a - b .* (current_R.^2);
            current_R = current_R + dR_dt * dt;
            current_R(current_R < 0) = 0;
            history_R(:, i) = current_R;
        end
        
        treePlot.XData = X;
        treePlot.YData = Y;
        sld.Value = 0;
        draw_frame(0);
    end

    function draw_frame(t_val)
        if isempty(history_R), return; end
        
        [~, idx] = min(abs(t_vec - t_val)); 
        current_R = history_R(:, idx);
        
        alive_mask = current_R > 0;
        num_alive = sum(alive_mask);
        
        if num_alive > 0
            avg_size = mean(current_R(alive_mask));
        else
            avg_size = 0;
        end
        
        treePlot.SizeData = max(current_R.^2 * 12, 1);
        title(ax, sprintf('Время: %.1f | Живых деревьев: %d | Ср. размер: %.1f', ...
              t_vec(idx), num_alive, avg_size));
    end

    spawn(); 
end