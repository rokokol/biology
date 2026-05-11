function AlievPanfilovModel()
    % Создание главного окна
    fig = uifigure('Name', 'Модель Алиева-Панфилова', 'Position', [100, 100, 1000, 600]);
    
    % Макет интерфейса
    gl = uigridlayout(fig, [1, 2]);
    gl.ColumnWidth = {'1x', 300};
    
    % Зона графиков
    axGrid = uigridlayout(gl, [2, 1]);
    ax1 = uiaxes(axGrid); 
    title(ax1, 'Распространение импульса (1D)', 'Interpreter', 'tex', 'FontSize', 14); 
    xlabel(ax1, 'Пространство \it{X}', 'Interpreter', 'tex'); 
    ylabel(ax1, 'Потенциал \it{u}, Восстановление \it{v}', 'Interpreter', 'tex');
    grid(ax1, 'on');
    
    ax2 = uiaxes(axGrid); 
    title(ax2, 'Фазовый портрет (\it{u} vs \it{v}) в центре', 'Interpreter', 'tex', 'FontSize', 14);
    xlabel(ax2, '\it{u} (Возбуждение)', 'Interpreter', 'tex'); 
    ylabel(ax2, '\it{v} (Восстановление)', 'Interpreter', 'tex');
    grid(ax2, 'on');
    
    % Зона управления
    ctrl = uigridlayout(gl, [14, 1]);
    ctrl.RowHeight = num2cell(repmat(30, 1, 14));
    
    p = struct('k', 8, 'a', 0.15, 'e0', 0.002, 'mu1', 0.2, 'mu2', 0.3);
    
    createSlider(ctrl, 'Параметр k (8)', 1, 15, p.k, @(v) updateParam('k', v));
    createSlider(ctrl, 'Параметр a (0.15)', 0.01, 0.5, p.a, @(v) updateParam('a', v));
    createSlider(ctrl, 'Параметр \epsilon_0 (0.002)', 0.0001, 0.01, p.e0, @(v) updateParam('e0', v));
    createSlider(ctrl, 'Параметр \mu_1 (0.2)', 0.01, 0.5, p.mu1, @(v) updateParam('mu1', v));
    createSlider(ctrl, 'Параметр \mu_2 (0.3)', 0.01, 0.5, p.mu2, @(v) updateParam('mu2', v));
    
    btnRun = uibutton(ctrl, 'Text', 'Старт / Пауза', 'ButtonPushedFcn', @toggleSim);
    btnReset = uibutton(ctrl, 'Text', 'Сброс и стимуляция', 'ButtonPushedFcn', @resetSim);
    
    nx = 100; dx = 1; dt = 0.05; 
    u = zeros(nx, 1); v = zeros(nx, 1);
    hist_u = []; hist_v = [];
    isRunning = false;
    
    line_u = plot(ax1, u, 'b', 'LineWidth', 2); hold(ax1, 'on');
    line_v = plot(ax1, v, 'r', 'LineWidth', 1.5); hold(ax1, 'off');
    legend(ax1, {'\it{u} (transmembrane)', '\it{v} (recovery)'}, 'Interpreter', 'tex', 'Location', 'best');
    ax1.YLim = [-0.2 1.2];
    
    line_phase = plot(ax2, 0, 0, 'k', 'LineWidth', 1.5);
    ax2.XLim = [-0.1 1.2]; ax2.YLim = [-0.1 0.5];
    
    resetSim();
    
    function updateParam(name, val)
        p.(name) = val;
    end

    function resetSim(~, ~)
        u = zeros(nx, 1); v = zeros(nx, 1);
        u(1:5) = 1; 
        hist_u = []; hist_v = [];
        updatePlots();
    end

    function toggleSim(~, ~)
        isRunning = ~isRunning;
        while isRunning && isvalid(fig)
            for step = 1:10
                du_rx = -p.k .* u .* (u - p.a) .* (u - 1) - u .* v;
                dv_rx = -(p.e0 + (p.mu1 .* v) ./ (u + p.mu2)) .* (v + p.k .* u .* (u - p.a - 1));
                
                lap_u = circshift(u, -1) - 2*u + circshift(u, 1);
                lap_u(1) = u(2) - u(1);         
                lap_u(end) = u(end-1) - u(end); 
                
                u = u + dt .* (du_rx + lap_u ./ (dx^2));
                v = v + dt .* dv_rx;
            end
            
            mid = round(nx/2);
            hist_u = [hist_u; u(mid)];
            hist_v = [hist_v; v(mid)];
            
            if length(hist_u) > 500
                hist_u(1) = []; hist_v(1) = [];
            end
            
            updatePlots();
            drawnow limitrate;
        end
    end

    function updatePlots()
        line_u.YData = u;
        line_v.YData = v;
        if ~isempty(hist_u)
            line_phase.XData = hist_u;
            line_phase.YData = hist_v;
        end
    end

    function createSlider(parent, lblText, minVal, maxVal, defaultVal, callback)
        uilabel(parent, 'Text', lblText, 'Interpreter', 'tex', 'FontSize', 14);
        sld = uislider(parent, 'Limits', [minVal maxVal], 'Value', defaultVal);
        sld.ValueChangedFcn = @(src, event) callback(src.Value);
    end
end
