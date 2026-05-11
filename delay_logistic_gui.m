function delay_logistic_gui()
    % Создание главного окна
    fig = uifigure('Name', 'Модель с запаздыванием', 'Position', [100 100 800 500]);

    % Главная сетка: 1 строка, 2 столбца
    % Левый тянется ('1x'), правый фиксирован (250px)
    main_grid = uigridlayout(fig, [1 2]);
    main_grid.ColumnWidth = {'1x', 250}; 
    
    % Оси графика в левой ячейке
    ax = uiaxes(main_grid);
    ax.Layout.Row = 1;
    ax.Layout.Column = 1;

    % Панель для элементов управления в правой ячейке
    control_panel = uipanel(main_grid, 'Title', 'Параметры');
    control_panel.Layout.Row = 1;
    control_panel.Layout.Column = 2;
    
    % Внутренняя сетка для панели: 8 строк, 1 столбец
    panel_grid = uigridlayout(control_panel, [8 1]);
    panel_grid.RowHeight = {22, 30, 22, 30, 22, 30, 22, 30}; % Чередование высоты для текста и слайдера
    
    % --- Элементы управления ---
    
    uilabel(panel_grid, 'Text', 'Скорость роста (r)');
    r_sld = uislider(panel_grid, 'Limits', [0.1 5], 'Value', 1.5);
    
    uilabel(panel_grid, 'Text', 'Емкость среды (K)');
    K_sld = uislider(panel_grid, 'Limits', [10 1000], 'Value', 100);
    
    uilabel(panel_grid, 'Text', 'Запаздывание (T)');
    T_sld = uislider(panel_grid, 'Limits', [0.1 5], 'Value', 1.2);
    
    uilabel(panel_grid, 'Text', 'Начальное знач. (N0)');
    N0_sld = uislider(panel_grid, 'Limits', [1 200], 'Value', 10);

    % --- Привязка событий ---
    r_sld.ValueChangedFcn = @(es,ed) update_plot();
    K_sld.ValueChangedFcn = @(es,ed) update_plot();
    T_sld.ValueChangedFcn = @(es,ed) update_plot();
    N0_sld.ValueChangedFcn = @(es,ed) update_plot();

    % Первичная отрисовка
    update_plot();

    % --- Функция расчета и обновления графика ---
    function update_plot()
        r = r_sld.Value;
        K = K_sld.Value;
        T = T_sld.Value;
        N0 = N0_sld.Value;

        t_end = 50; 
        
        dde_fun = @(t, y, Z) r * y * (1 - Z / K);
        
        try
            sol = dde23(dde_fun, T, N0, [0 t_end]);
            
            plot(ax, sol.x, sol.y, 'LineWidth', 2, 'Color', '#0072BD');
            title(ax, 'Динамика популяции (уравнение Хатчинсона)');
            xlabel(ax, 'Время (t)');
            ylabel(ax, 'Численность (N)');
            grid(ax, 'on');
            ylim(ax, [0, K * 2.5]); 
        catch ME
            title(ax, 'Ошибка вычислений');
        end
    end
end
