function tumor_model_gui()
    % Создание главного окна
    fig = uifigure('Name', 'Модель динамики опухоли', 'Position', [100 100 1200 700]);
    layout = uigridlayout(fig, [1 2]);
    layout.ColumnWidth = {280, '1x'};
    
    % Панель управления (слева)
    ctrlPanel = uipanel(layout, 'Title', 'Параметры модели');
    ctrlLayout = uigridlayout(ctrlPanel, [10 2]);
    ctrlLayout.RowHeight = repmat({30}, 1, 10);
    ctrlLayout.ColumnWidth = {'1x', 70};
    
    % Функция-хелпер для создания полей ввода
   function ef = addParam(row, labelText, defaultVal)
        lbl = uilabel(ctrlLayout, 'Text', labelText, 'HorizontalAlignment', 'right', 'Interpreter', 'latex');
        lbl.Layout.Row = row;
        lbl.Layout.Column = 1;
        
        ef = uieditfield(ctrlLayout, 'numeric', 'Value', defaultVal);
        ef.Layout.Row = row;
        ef.Layout.Column = 2;
    end 
    
    % Инициализация параметров (значения по умолчанию)
    e_l1 = addParam(1, '$\lambda_1$ (ест. убыль лимфоцитов):', 0.1);
    e_l2 = addParam(2, '$\lambda_2$ (рост опухоли):', 0.5);
    e_a1 = addParam(3, '$\alpha_1$ (рост лимфоцитов):', 1.0);
    e_a2 = addParam(4, '$\alpha_2$ (уничтожение опухоли):', 1.0);
    e_xc = addParam(5, '$x_c$ (предел лимфоцитов):', 10);
    e_x0 = addParam(6, '$x(0)$ (нач. лимфоциты):', 1.5);
    e_y0 = addParam(7, '$y(0)$ (нач. опухоль):', 2.0);
    e_T  = addParam(8, '$T$ (время моделирования):', 100);
    
    % Кнопка запуска
    btn = uibutton(ctrlLayout, 'Text', 'Рассчитать', 'ButtonPushedFcn', @(btn,event) updatePlots());
    btn.Layout.Row = 10; btn.Layout.Column = [1 2];
    
    % Панель графиков (справа)
    plotLayout = uigridlayout(layout, [2 2]);
    plotLayout.RowHeight = {'1x', '1x'};
    plotLayout.ColumnWidth = {'1x', '1x'};
    
    % График 1: Временная динамика (широкий, сверху)
    axTime = uiaxes(plotLayout);
    axTime.Layout.Row = 1; axTime.Layout.Column = [1 2];
    title(axTime, 'Временная динамика популяций');
    xlabel(axTime, 'Время, t'); ylabel(axTime, 'Численность');
    
    % График 2: Фазовый портрет (снизу слева)
    axPhase = uiaxes(plotLayout);
    axPhase.Layout.Row = 2; axPhase.Layout.Column = 1;
    title(axPhase, 'Фазовый портрет');
    xlabel(axPhase, 'Лимфоциты (x)'); ylabel(axPhase, 'Опухоль (y)');
    
    % График 3: Анализ равновесий (снизу справа)
    axEq = uiaxes(plotLayout);
    axEq.Layout.Row = 2; axEq.Layout.Column = 2;
    title(axEq, 'Поиск патологических состояний равновесия');
    xlabel(axEq, 'x (лимфоциты)'); ylabel(axEq, '\psi(x)');
    
    % Основная функция вычислений и отрисовки
    function updatePlots()
        % Считывание параметров
        p.l1 = e_l1.Value; p.l2 = e_l2.Value;
        p.a1 = e_a1.Value; p.a2 = e_a2.Value; p.xc = e_xc.Value;
        Y0 = [e_x0.Value; e_y0.Value];
        T = e_T.Value;
        
        % 1. Решение ОДУ
        % Используем abs(Y(2))^(2/3) для защиты от комплексных чисел при микро-колебаниях у нуля
        odefun = @(t, Y) [
            -p.l1*Y(1) + p.a1 * (Y(1) * abs(Y(2))^(2/3) * (1 - Y(1)/p.xc)) / (1 + Y(1));
             p.l2*Y(2) - p.a2 * (Y(1) * abs(Y(2))^(2/3)) / (1 + Y(1))
        ];
        
        % Опция NonNegative критична для биологических моделей
        options = odeset('RelTol', 1e-6, 'AbsTol', 1e-8, 'NonNegative', [1 2]);
        [t, Y] = ode45(odefun, [0 T], Y0, options);
        
        % 2. Отрисовка временной динамики
        cla(axTime);
        plot(axTime, t, Y(:,1), 'b-', 'LineWidth', 2, 'DisplayName', 'Лимфоциты (x)');
        hold(axTime, 'on');
        plot(axTime, t, Y(:,2), 'r-', 'LineWidth', 2, 'DisplayName', 'Опухоль (y)');
        hold(axTime, 'off');
        legend(axTime, 'Location', 'best'); grid(axTime, 'on');
        
        % 3. Отрисовка фазового портрета с векторным полем
        cla(axPhase);
        xmax = max(max(Y(:,1))*1.2, 0.1);
        ymax = max(max(Y(:,2))*1.2, 0.1);
        
        % Сетка для векторного поля
        [X_grid, Y_grid] = meshgrid(linspace(0, xmax, 25), linspace(0, ymax, 25));
        DX = -p.l1.*X_grid + p.a1 .* (X_grid .* abs(Y_grid).^(2/3) .* (1 - X_grid./p.xc)) ./ (1 + X_grid);
        DY = p.l2.*Y_grid - p.a2 .* (X_grid .* abs(Y_grid).^(2/3)) ./ (1 + X_grid);
        
        % Нормализация стрелок для красоты поля
        L = sqrt(DX.^2 + DY.^2);
        L(L == 0) = 1; % Защита от деления на ноль
        quiver(axPhase, X_grid, Y_grid, DX./L, DY./L, 0.5, 'Color', [0.7 0.7 0.7], 'HandleVisibility', 'off');
        
        hold(axPhase, 'on');
        plot(axPhase, Y(:,1), Y(:,2), 'k-', 'LineWidth', 2, 'DisplayName', 'Траектория');
        plot(axPhase, Y0(1), Y0(2), 'go', 'MarkerFaceColor', 'g', 'DisplayName', 'Старт');
        plot(axPhase, Y(end,1), Y(end,2), 'ro', 'MarkerFaceColor', 'r', 'DisplayName', 'Конец');
        hold(axPhase, 'off');
        grid(axPhase, 'on'); legend(axPhase, 'Location', 'best');
        xlim(axPhase, [0 xmax]); ylim(axPhase, [0 ymax]);
        
        % 4. Отрисовка функции равновесия \psi(x) и уровня k1 (формулы 3 и 4)
        cla(axEq);
        x_val = linspace(0, p.xc, 500);
        psi = (x_val.^2 .* (1 - x_val./p.xc)) ./ (1 + x_val).^3;
        k1 = (p.l1 * p.l2^2) / (p.a1 * p.a2^2);
        
        plot(axEq, x_val, psi, 'b-', 'LineWidth', 2, 'DisplayName', '\psi(x; x_c)');
        hold(axEq, 'on');
        yline(axEq, k1, 'r--', ['k_1 = ', num2str(k1, 4)], 'LineWidth', 1.5, 'DisplayName', 'Уровень k_1', 'LabelHorizontalAlignment', 'left');
        hold(axEq, 'off');
        grid(axEq, 'on'); legend(axEq, 'Location', 'northeast');
        xlim(axEq, [0 p.xc]);
        ylim(axEq, [0 max(max(psi)*1.2, k1*1.5)]);
    end

    % Первоначальный расчёт при запуске
    updatePlots();
end
