function tree_gui_simple
    f = uifigure('Name', 'Рост дерева (t0=0)', 'Position', [100 100 600 500]);
    
    mainGrid = uigridlayout(f, [2, 1]);
    mainGrid.RowHeight = {'1x', 'fit'}; 

    ax = uiaxes(mainGrid);
    
    ctrlGrid = uigridlayout(mainGrid, [2, 2]);
    ctrlGrid.ColumnWidth = {80, '1x'};
    ctrlGrid.RowHeight = {30, 30};

    uilabel(ctrlGrid, 'Text', 'Энергия (a):');
    sldA = uislider(ctrlGrid, 'Limits', [0.1 10], 'Value', 2);
    
    uilabel(ctrlGrid, 'Text', 'Расход (b):');
    sldB = uislider(ctrlGrid, 'Limits', [0.01 1], 'Value', 0.1);

    cbk = @(s, e) update(ax, sldA.Value, sldB.Value);
    sldA.ValueChangingFcn = @(s, e) update(ax, e.Value, sldB.Value);
    sldB.ValueChangingFcn = @(s, e) update(ax, sldA.Value, e.Value);

    update(ax, sldA.Value, sldB.Value); 
end

function update(ax, a, b)
    cla(ax);
    hold(ax, 'on');

    [T_grid, X_grid] = meshgrid(0:2.5:50, 0:1:15); 
    
    U = ones(size(T_grid)); 
    V = a - b .* X_grid.^2; 
    
    L = sqrt(U.^2 + V.^2);
    U_norm = U ./ L;
    V_norm = V ./ L;
    
    quiver(ax, T_grid, X_grid, U_norm, V_norm, 0.5, 'Color', [0.7 0.7 0.7]);

    t = linspace(0, 50, 200);
    x = sqrt(a/b) * tanh(sqrt(a*b) * t); 
    plot(ax, t, x, 'LineWidth', 2.5, 'Color', '#2E7D32');
    
    hold(ax, 'off');
    grid(ax, 'on');
    xlabel(ax, 't');   
    ylabel(ax, 'x');
    title(ax, sprintf('Предел роста L = %.2f (a=%.1f, b=%.2f)', sqrt(a/b), a, b));
    ylim(ax, [0, 15]); 
end