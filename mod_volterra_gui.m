function mod_volterra_gui()
    % Создание главного окна
    fig = uifigure('Name', 'Модифицированная модель Вольтерры', 'Position', [100, 100, 950, 600]);
    g = uigridlayout(fig, [1 2]);
    g.ColumnWidth = {'1x', 280};

    % Панель графиков
    plot_grid = uigridlayout(g, [2 1]);
    ax_time = uiaxes(plot_grid); title(ax_time, 'Временной ряд t -> (x, y)'); hold(ax_time, 'on'); grid(ax_time, 'on');
    ax_phase = uiaxes(plot_grid); title(ax_phase, 'Фазовая плоскость (x, y)'); hold(ax_phase, 'on'); grid(ax_phase, 'on');

    % Панель управления (параметры и кнопки)
    ctrl = uigridlayout(g, [15 2]);
    ctrl.RowHeight = repmat({25}, 1, 15);

    % Дефолтные параметры (согласно системе на доске)
    params = {'a1', 2; 'b1', 1; 'c1', 0.1; 
              'a2', 1; 'b2', 1; 'c2', 0.1; 
              'x0', 2; 'y0', 2; 'T_max', 30};
    fields = struct();

    % Генерация полей ввода
    for i = 1:size(params, 1)
        uilabel(ctrl, 'Text', params{i, 1});
        fields.(params{i, 1}) = uieditfield(ctrl, 'numeric', 'Value', params{i, 2}, ...
            'ValueChangedFcn', @(~,~) update_plots());
    end

    % Кнопки для стационарных точек
    uilabel(ctrl, 'Text', 'Стационарные точки (x*, y*):'); uilabel(ctrl, 'Text', '');
    uibutton(ctrl, 'Text', 'SP1: (0, 0)', 'ButtonPushedFcn', @(~,~) set_sp(1));
    uibutton(ctrl, 'Text', 'SP2: Жертва без хищника', 'ButtonPushedFcn', @(~,~) set_sp(2));
    uibutton(ctrl, 'Text', 'SP3: Хищник без жертвы', 'ButtonPushedFcn', @(~,~) set_sp(3));
    uibutton(ctrl, 'Text', 'SP4: Сосуществование', 'ButtonPushedFcn', @(~,~) set_sp(4));

    % Первичная отрисовка
    update_plots();

    % --- Вложенные функции ---
    function update_plots()
        % 1. Чтение параметров
        a1 = fields.a1.Value; b1 = fields.b1.Value; c1 = fields.c1.Value;
        a2 = fields.a2.Value; b2 = fields.b2.Value; c2 = fields.c2.Value;
        x0 = fields.x0.Value; y0 = fields.y0.Value; T  = fields.T_max.Value;

        % 2. Система ОДУ (по фото)
        % dx/dt = a1*x - b1*x*y - c1*x^2
        % dy/dt = -a2*y + b2*x*y - c2*y^2
        ode = @(t, Y) [
            Y(1)*(a1 - b1*Y(2) - c1*Y(1));
            Y(2)*(-a2 + b2*Y(1) - c2*Y(2))
        ];

        % 3. Численное интегрирование
        [t, Y] = ode45(ode, [0 T], [x0 y0]);

        % 4. Очистка и рендер графиков
        cla(ax_time); cla(ax_phase);
        
        % Временной ряд
        plot(ax_time, t, Y(:,1), 'b-', 'LineWidth', 1.5, 'DisplayName', 'x (Жертва)');
        plot(ax_time, t, Y(:,2), 'r-', 'LineWidth', 1.5, 'DisplayName', 'y (Хищник)');
        legend(ax_time);
        
        % Фазовый портрет
        plot(ax_phase, Y(:,1), Y(:,2), 'k-', 'LineWidth', 1.2);
        plot(ax_phase, Y(1,1), Y(1,2), 'go', 'MarkerFaceColor', 'g'); % Старт
        plot(ax_phase, Y(end,1), Y(end,2), 'ro', 'MarkerFaceColor', 'r'); % Конец
        xlabel(ax_phase, 'x'); ylabel(ax_phase, 'y');
    end

    function set_sp(type)
        % Расчет стационарных точек
        a1 = fields.a1.Value; b1 = fields.b1.Value; c1 = fields.c1.Value;
        a2 = fields.a2.Value; b2 = fields.b2.Value; c2 = fields.c2.Value;
        
        switch type
            case 1
                x_sp = 0; y_sp = 0;
            case 2
                x_sp = a1/c1; y_sp = 0;
            case 3
                x_sp = 0; y_sp = -a2/c2;
            case 4
                det = c1*c2 + b1*b2;
                x_sp = (a1*c2 + a2*b1)/det;
                y_sp = (a1*b2 - a2*c1)/det;
        end
        
        % Присвоение новых НУ с микро-возмущением для визуализации характера точки
        fields.x0.Value = x_sp + 0.05; 
        fields.y0.Value = y_sp + 0.05;
        update_plots();
    end
end
