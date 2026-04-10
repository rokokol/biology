function logistic_harvest_stability_gui
    fig = uifigure('Name', 'logistic_harvest_stability_gui', ...
        'Position', [100 80 1180 780], 'Color', [1 1 1]);

    mainGrid = uigridlayout(fig, [3, 2]);
    mainGrid.RowHeight = {72, '1x', '1x'};
    mainGrid.ColumnWidth = {'1x', '1x'};
    mainGrid.Padding = [10 10 10 10];

    ctrlGrid = uigridlayout(mainGrid, [2, 3]);
    ctrlGrid.Layout.Row = 1;
    ctrlGrid.Layout.Column = [1 2];
    ctrlGrid.RowHeight = {24, 24};
    ctrlGrid.ColumnWidth = {46, '1x', 70};
    ctrlGrid.ColumnSpacing = 10;
    ctrlGrid.RowSpacing = 6;
    ctrlGrid.Padding = [0 0 0 0];

    uilabel(ctrlGrid, 'Text', 'v', 'HorizontalAlignment', 'right', ...
        'FontName', 'Times New Roman', 'FontSize', 16);
    vSlider = uislider(ctrlGrid, 'Limits', [0 0.45], 'Value', 0.18);
    vSlider.Layout.Row = 1;
    vSlider.Layout.Column = 2;

    vValueLabel = uilabel(ctrlGrid, 'Text', '', 'HorizontalAlignment', 'left', ...
        'FontName', 'Courier New');
    vValueLabel.Layout.Row = 1;
    vValueLabel.Layout.Column = 3;

    y0Label = uilabel(ctrlGrid, 'Text', 'y_0', 'HorizontalAlignment', 'right', ...
        'FontName', 'Times New Roman', 'FontSize', 16);
    y0Label.Layout.Row = 2;
    y0Label.Layout.Column = 1;

    y0Slider = uislider(ctrlGrid, 'Limits', [-0.2 1.6], 'Value', 0.8);
    y0Slider.Layout.Row = 2;
    y0Slider.Layout.Column = 2;

    y0ValueLabel = uilabel(ctrlGrid, 'Text', '', 'HorizontalAlignment', 'left', ...
        'FontName', 'Courier New');
    y0ValueLabel.Layout.Row = 2;
    y0ValueLabel.Layout.Column = 3;

    axRate = uiaxes(mainGrid);
    axRate.Layout.Row = 2;
    axRate.Layout.Column = 1;

    axPhase = uiaxes(mainGrid);
    axPhase.Layout.Row = 2;
    axPhase.Layout.Column = 2;

    axTime = uiaxes(mainGrid);
    axTime.Layout.Row = 3;
    axTime.Layout.Column = 1;

    axBif = uiaxes(mainGrid);
    axBif.Layout.Row = 3;
    axBif.Layout.Column = 2;

    vSlider.ValueChangingFcn = @(~, e) refresh(e.Value, []);
    vSlider.ValueChangedFcn = @(~, e) refresh(e.Value, []);
    y0Slider.ValueChangingFcn = @(~, e) refresh([], e.Value);
    y0Slider.ValueChangedFcn = @(~, e) refresh([], e.Value);

    refresh([], []);

    function refresh(vOverride, y0Override)
        if isempty(vOverride)
            v = vSlider.Value;
        else
            v = vOverride;
        end

        if isempty(y0Override)
            y0 = y0Slider.Value;
        else
            y0 = y0Override;
        end

        tMax = 20;

        vValueLabel.Text = sprintf('= %.3f', v);
        y0ValueLabel.Text = sprintf('= %.3f', y0);
        vSlider.Value = v;
        y0Slider.Value = y0;

        [eqPoints, eqKinds] = analyze_system(v);

        update_rate_plot(v, eqPoints, eqKinds);
        update_phase_plot(v, eqPoints, eqKinds);
        update_time_plot(v, y0, tMax, eqPoints, eqKinds);
        update_bifurcation_plot(v, eqPoints, eqKinds);
    end

    function update_rate_plot(v, eqPoints, eqKinds)
        yGrid = linspace(-1.2, 2.0, 700);
        fGrid = rhs(yGrid, v);

        cla(axRate);
        hold(axRate, 'on');
        plot(axRate, yGrid, fGrid, 'LineWidth', 1.8, 'Color', [0.00 0.20 0.55]);
        plot_horizontal_reference(axRate, 0, '--', [0.40 0.40 0.40], 0.9);
        plot_vertical_reference(axRate, 0, ':', [0.70 0.70 0.70], 0.9);

        for k = 1:numel(eqPoints)
            plot_equilibrium_marker(axRate, eqPoints(k), 0, eqKinds{k});
        end

        hold(axRate, 'off');
        grid(axRate, 'on');
        xlabel(axRate, '$y$', 'Interpreter', 'latex');
        ylabel(axRate, '$\dot y$', 'Interpreter', 'latex');
        title(axRate, sprintf('$f(y)=y-y^2-%.3f$', v), 'Interpreter', 'latex');
        xlim(axRate, [yGrid(1) yGrid(end)]);
    end

    function update_phase_plot(v, eqPoints, eqKinds)
        yMin = -1.2;
        yMax = 2.0;
        xCenter = 0.5;

        cla(axPhase);
        hold(axPhase, 'on');
        plot(axPhase, [xCenter xCenter], [yMin yMax], 'k-', 'LineWidth', 1.4);

        cuts = [yMin; eqPoints(:); yMax];
        for k = 1:(numel(cuts) - 1)
            yA = cuts(k);
            yB = cuts(k + 1);
            if yB - yA < 1e-6
                continue;
            end

            yMid = 0.5 * (yA + yB);
            flow = rhs(yMid, v);
            yStart = yA + 0.20 * (yB - yA);
            yEnd = yB - 0.20 * (yB - yA);

            if flow > 0
                quiver(axPhase, xCenter, yStart, 0, yEnd - yStart, 0, ...
                    'LineWidth', 1.4, 'MaxHeadSize', 0.55, 'Color', [0.15 0.15 0.15]);
            elseif flow < 0
                quiver(axPhase, xCenter, yEnd, 0, yStart - yEnd, 0, ...
                    'LineWidth', 1.4, 'MaxHeadSize', 0.55, 'Color', [0.15 0.15 0.15]);
            end
        end

        for k = 1:numel(eqPoints)
            plot_equilibrium_marker(axPhase, xCenter, eqPoints(k), eqKinds{k});
            text(axPhase, 0.58, eqPoints(k), equilibrium_label(eqPoints(k), eqKinds{k}), ...
                'FontSize', 11, 'VerticalAlignment', 'middle', 'Interpreter', 'latex');
        end

        hold(axPhase, 'off');
        grid(axPhase, 'on');
        title(axPhase, '$\dot y = f(y)$', 'Interpreter', 'latex');
        xlim(axPhase, [0 1]);
        ylim(axPhase, [yMin yMax]);
        axPhase.XTick = [];
        ylabel(axPhase, '$y$', 'Interpreter', 'latex');
    end

    function update_time_plot(v, y0, tMax, eqPoints, eqKinds)
        sampleY0 = unique(sort([-0.2 0.1 0.35 0.6 0.9 1.3 y0]));

        cla(axTime);
        hold(axTime, 'on');

        for k = 1:numel(sampleY0)
            [tSol, ySol] = simulate_trajectory(v, sampleY0(k), tMax);
            if abs(sampleY0(k) - y0) < 1e-9
                plot(axTime, tSol, ySol, 'LineWidth', 2.0, 'Color', [0.00 0.20 0.60]);
            else
                plot(axTime, tSol, ySol, 'LineWidth', 0.9, 'Color', [0.68 0.68 0.74]);
            end
        end

        plot_horizontal_reference(axTime, 0, '--', [0.40 0.40 0.40], 0.9);
        text(axTime, 0.02 * tMax, 0.03, '$y=0$', 'Color', [0.35 0.35 0.35], ...
            'FontSize', 11, 'Interpreter', 'latex');
        for k = 1:numel(eqPoints)
            style = '--';
            if strcmp(eqKinds{k}, 'semi')
                style = ':';
            end
            plot_horizontal_reference(axTime, eqPoints(k), style, equilibrium_color(eqKinds{k}), 0.9);
        end

        hold(axTime, 'off');
        grid(axTime, 'on');
        xlabel(axTime, '$t$', 'Interpreter', 'latex');
        ylabel(axTime, '$y(t)$', 'Interpreter', 'latex');
        title(axTime, sprintf('$y(0)=%.3f$', y0), 'Interpreter', 'latex');
        xlim(axTime, [0 tMax]);
        ylim(axTime, [-1.2 2.0]);
    end

    function update_bifurcation_plot(v, eqPoints, eqKinds)
        vGrid = linspace(0, 0.45, 500);
        disc = 1 - 4 * vGrid;
        valid = disc >= 0;

        lowerBranch = NaN(size(vGrid));
        upperBranch = NaN(size(vGrid));
        lowerBranch(valid) = (1 - sqrt(disc(valid))) / 2;
        upperBranch(valid) = (1 + sqrt(disc(valid))) / 2;

        cla(axBif);
        hold(axBif, 'on');
        plot(axBif, vGrid, lowerBranch, '--', 'LineWidth', 1.6, 'Color', [0.60 0.15 0.15]);
        plot(axBif, vGrid, upperBranch, '-', 'LineWidth', 1.8, 'Color', [0.10 0.45 0.10]);
        plot(axBif, 0.25, 0.5, 'o', 'MarkerSize', 8, ...
            'MarkerFaceColor', [0.90 0.90 0.90], 'MarkerEdgeColor', [0.20 0.20 0.20]);
        plot_vertical_reference(axBif, 0.25, ':', [0.40 0.40 0.40], 0.9);
        text(axBif, 0.257, 1.02, '$v=\frac{1}{4}$', 'Color', [0.35 0.35 0.35], ...
            'FontSize', 11, 'Interpreter', 'latex');
        plot_vertical_reference(axBif, v, '-', [0.00 0.20 0.60], 1.2);

        for k = 1:numel(eqPoints)
            plot(axBif, v, eqPoints(k), 'o', 'MarkerSize', 9, ...
                'MarkerFaceColor', equilibrium_color(eqKinds{k}), 'MarkerEdgeColor', [0 0 0]);
        end

        hold(axBif, 'off');
        grid(axBif, 'on');
        xlabel(axBif, '$v$', 'Interpreter', 'latex');
        ylabel(axBif, '$y^*(v)$', 'Interpreter', 'latex');
        title(axBif, '$y^*=y^*(v)$', 'Interpreter', 'latex');
        xlim(axBif, [0 0.45]);
        ylim(axBif, [0 1.1]);
    end

    function [eqPoints, eqKinds] = analyze_system(v)
        tol = 1e-9;
        disc = 1 - 4 * v;

        if disc > tol
            rootDisc = sqrt(disc);
            y1 = (1 - rootDisc) / 2;
            y2 = (1 + rootDisc) / 2;
            eqPoints = [y1; y2];
            eqKinds = {'unstable'; 'stable'};
        elseif abs(disc) <= tol
            eqPoints = 0.5;
            eqKinds = {'semi'};
        else
            eqPoints = [];
            eqKinds = {};
        end
    end

    function [tSol, ySol] = simulate_trajectory(v, yStart, tMax)
        opts = odeset('RelTol', 1e-6, 'AbsTol', 1e-8, ...
            'Events', @(t, y) trajectory_bounds_event(t, y));
        [tSol, ySol] = ode45(@(~, y) rhs(y, v), [0 tMax], yStart, opts);
        ySol = ySol(:, 1);
    end

    function [value, isterminal, direction] = trajectory_bounds_event(~, y)
        value = [y(1) + 1.2; 2.0 - y(1)];
        isterminal = [1; 1];
        direction = [0; 0];
    end

    function out = rhs(y, v)
        out = y - y.^2 - v;
    end

    function plot_equilibrium_marker(ax, x, y, kind)
        plot(ax, x, y, 'o', 'MarkerSize', 9, ...
            'MarkerFaceColor', equilibrium_color(kind), 'MarkerEdgeColor', [0 0 0], ...
            'LineWidth', 1.0);
    end

    function plot_horizontal_reference(ax, yValue, lineStyle, colorValue, lineWidth)
        xl = xlim(ax);
        plot(ax, xl, [yValue yValue], 'LineStyle', lineStyle, ...
            'Color', colorValue, 'LineWidth', lineWidth);
    end

    function plot_vertical_reference(ax, xValue, lineStyle, colorValue, lineWidth)
        yl = ylim(ax);
        plot(ax, [xValue xValue], yl, 'LineStyle', lineStyle, ...
            'Color', colorValue, 'LineWidth', lineWidth);
    end

    function labelText = equilibrium_label(yEq, kind)
        switch kind
            case 'stable'
                labelText = sprintf('$y_2=%.3f$', yEq);
            case 'unstable'
                labelText = sprintf('$y_1=%.3f$', yEq);
            otherwise
                labelText = sprintf('$y^*=%.3f$', yEq);
        end
    end

    function color = equilibrium_color(kind)
        switch kind
            case 'stable'
                color = [0.05 0.60 0.20];
            case 'unstable'
                color = [0.85 0.20 0.20];
            otherwise
                color = [0.95 0.72 0.20];
        end
    end
end
