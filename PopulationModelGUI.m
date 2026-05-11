function PopulationModelGUI()
    % Создание главного окна
    fig = figure('Name', 'Модели роста популяции', ...
                 'Position', [100, 100, 850, 550], ...
                 'MenuBar', 'none', ...
                 'NumberTitle', 'off');

    % Оси для графиков
    ax = axes('Parent', fig, 'Position', [0.35, 0.15, 0.6, 0.75]);

    % Элементы управления (Inputs)
    uicontrol('Style', 'text', 'Position', [20, 460, 180, 20], ...
              'String', 'Начальная популяция (P0):', 'HorizontalAlignment', 'left');
    editP0 = uicontrol('Style', 'edit', 'Position', [210, 460, 60, 20], 'String', '100'); % Увеличено для старта

    uicontrol('Style', 'text', 'Position', [20, 420, 180, 20], ...
              'String', 'Скорость роста (r):', 'HorizontalAlignment', 'left');
    editR = uicontrol('Style', 'edit', 'Position', [210, 420, 60, 20], 'String', '0.1');

    uicontrol('Style', 'text', 'Position', [20, 380, 180, 20], ...
              'String', 'Емкость среды (K):', 'HorizontalAlignment', 'left');
    editK = uicontrol('Style', 'edit', 'Position', [210, 380, 60, 20], 'String', '1000');

    uicontrol('Style', 'text', 'Position', [20, 340, 180, 20], ...
              'String', 'Время симуляции (T):', 'HorizontalAlignment', 'left');
    editT = uicontrol('Style', 'edit', 'Position', [210, 340, 60, 20], 'String', '150');

    % Новое поле для квоты изъятия (v)
    uicontrol('Style', 'text', 'Position', [20, 300, 180, 20], ...
              'String', 'Квота изъятия (v):', 'HorizontalAlignment', 'left');
    editV = uicontrol('Style', 'edit', 'Position', [210, 300, 60, 20], 'String', '15');

    % Кнопка запуска
    uicontrol('Style', 'pushbutton', 'Position', [20, 240, 250, 40], ...
              'String', 'Построить / Обновить графики', 'Callback', @updatePlot);

    % Первичная отрисовка
    updatePlot();

    % Функция обновления графика
    function updatePlot(~, ~)
        % Считывание параметров
        P0 = str2double(get(editP0, 'String'));
        r  = str2double(get(editR, 'String'));
        K  = str2double(get(editK, 'String'));
        T  = str2double(get(editT, 'String'));
        v  = str2double(get(editV, 'String'));

        % Вектор времени для аналитики
        t = linspace(0, T, 500);

        % 1. Модель Мальтуса (аналитика)
        P_malthus = P0 * exp(r * t);

        % 2. Логистическая модель без изъятия (аналитика)
        P_logistic = K ./ (1 + ((K - P0) / P0) * exp(-r * t));

        % 3. Логистическая модель с изъятием (численное решение)
        % Функция: dP/dt = r*P*(1 - P/K) - v
        ode_fun = @(t_val, P_val) r * P_val * (1 - P_val / K) - v;
        
        % Решаем ОДУ
        [t_num, P_num] = ode45(ode_fun, t, P0);
        
        % Фильтруем отрицательные значения (вымирание популяции)
        P_num(P_num < 0) = NaN;

        % Отрисовка
        plot(ax, t, P_malthus, 'r--', 'LineWidth', 2);
        hold(ax, 'on');
        plot(ax, t, P_logistic, 'b-', 'LineWidth', 2);
        plot(ax, t_num, P_num, 'g-', 'LineWidth', 2); % Новая кривая
        hold(ax, 'off');

        % Оформление
        grid(ax, 'on');
        legend(ax, 'Мальтусовская (Экспонента)', ...
                   'Логистическая (Ограничена K)', ...
                   sprintf('С квотой (v = %g)', v), ...
                   'Location', 'northwest');
        xlabel(ax, 'Время (t)');
        ylabel(ax, 'Размер популяции (P)');
        title(ax, 'Сравнение моделей роста');
        
        % Ограничение оси Y
        ylim(ax, [0, K * 1.5]);
    end
end
