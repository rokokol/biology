function virus_antibody()
    % Используем классический figure для максимальной совместимости
    fig = figure('Name', 'Моделирование по Г.И. Марчуку', ...
        'Units', 'pixels', 'Position', [100 100 1000 750], ...
        'MenuBar', 'none', 'NumberTitle', 'off', 'Color', [0.94 0.94 0.94]);

    % Заголовок параметров
    uicontrol('Style', 'text', 'String', 'Параметры модели (Таблица)', ...
        'Position', [20 710 280 25], 'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', [0.94 0.94 0.94]);

    % Создаем поля ввода
    f = struct();
    % Названия, значения по умолчанию, ключ, Y-позиция
    params = {
        'beta (размн. V)', 2, 'beta', 670;
        'gamma (эфф. F)', 0.8, 'gamma', 640;
        'alpha (стим. C)', 10000, 'alpha', 610;
        'mu_c (гиб. C)', 0.5, 'mu_c', 580;
        'rho (прод. F)', 0.17, 'rho', 550;
        'eta (расх. F)', 10, 'eta', 520;
        'mu_f (гиб. F)', 0.17, 'mu_f', 490;
        'sigma (пор. m)', 10, 'sigma', 460;
        'mu_m (восс. m)', 0.12, 'mu_m', 430;
        'C0 (фон C)', 1, 'C0', 400;
        'tau (запазд.)', 0.5, 'tau', 370;
        'V0 (нач. вирус)', 1e-6, 'V0', 340
    };

    for i = 1:size(params, 1)
        uicontrol('Style', 'text', 'String', params{i,1}, ...
            'Position', [20 params{i,4} 160 20], 'HorizontalAlignment', 'left', 'BackgroundColor', [0.94 0.94 0.94]);
        f.(params{i,3}) = uicontrol('Style', 'edit', 'String', num2str(params{i,2}), ...
            'Position', [180 params{i,4} 120 25], 'BackgroundColor', 'white');
    end

    % Кнопки пресетов
    uicontrol('Style', 'text', 'String', 'Пресеты форм болезни:', ...
        'Position', [20 290 280 20], 'FontWeight', 'bold', 'BackgroundColor', [0.94 0.94 0.94]);
    
    uicontrol('Style', 'pushbutton', 'String', 'а) Субклиническая', 'Position', [20 255 135 30], 'Callback', @(s,e) set_p(f, 'a'));
    uicontrol('Style', 'pushbutton', 'String', 'в) Острая', 'Position', [165 255 135 30], 'Callback', @(s,e) set_p(f, 'v'));
    uicontrol('Style', 'pushbutton', 'String', 'б) Хроническая', 'Position', [20 220 135 30], 'Callback', @(s,e) set_p(f, 'b'));
    uicontrol('Style', 'pushbutton', 'String', 'г) Летальная', 'Position', [165 220 135 30], 'Callback', @(s,e) set_p(f, 'g'));

    % Основные кнопки управления
    ax = axes('Units', 'pixels', 'Position', [380 150 550 500]);
    title(ax, 'Динамика концентрации антигенов V(t)');
    grid(ax, 'on');

    uicontrol('Style', 'pushbutton', 'String', 'РАССЧИТАТЬ', ...
        'Position', [20 120 280 50], 'BackgroundColor', [0.8 1 0.8], 'FontSize', 12, 'FontWeight', 'bold', ...
        'Callback', @(s,e) run_m(ax, f));
    
    uicontrol('Style', 'pushbutton', 'String', 'Очистить график', ...
        'Position', [20 80 280 30], 'Callback', @(s,e) cla(ax));
end

function set_p(f, mode)
    % Базовые значения из таблицы (общие)
    set(f.mu_c, 'String', '0.5'); set(f.rho, 'String', '0.17');
    set(f.eta, 'String', '10'); set(f.mu_f, 'String', '0.17');
    set(f.mu_m, 'String', '0.12'); set(f.C0, 'String', '1');
    
    switch mode
        case 'a'
            set(f.beta, 'String', '8'); set(f.gamma, 'String', '10'); set(f.alpha, 'String', '10000');
            set(f.sigma, 'String', '10'); set(f.tau, 'String', '0.5'); set(f.V0, 'String', '1e-7');
        case 'v'
            set(f.beta, 'String', '2'); set(f.gamma, 'String', '0.8'); set(f.alpha, 'String', '10000');
            set(f.sigma, 'String', '10'); set(f.tau, 'String', '0.5'); set(f.V0, 'String', '1e-6');
        case 'b'
            set(f.beta, 'String', '1'); set(f.gamma, 'String', '0.8'); set(f.alpha, 'String', '1000');
            set(f.sigma, 'String', '10'); set(f.tau, 'String', '0.5'); set(f.V0, 'String', '1e-6');
        case 'g'
            set(f.beta, 'String', '1.5'); set(f.gamma, 'String', '0.8'); set(f.alpha, 'String', '800');
            set(f.sigma, 'String', '12'); set(f.tau, 'String', '2.6'); set(f.V0, 'String', '1e-6');
    end
end

function run_m(ax, f)
    % Считываем данные из полей ввода
    p.beta = str2double(get(f.beta, 'String'));
    p.gamma = str2double(get(f.gamma, 'String'));
    p.alpha = str2double(get(f.alpha, 'String'));
    p.mu_c = str2double(get(f.mu_c, 'String'));
    p.rho = str2double(get(f.rho, 'String'));
    p.eta = str2double(get(f.eta, 'String'));
    p.mu_f = str2double(get(f.mu_f, 'String'));
    p.sigma = str2double(get(f.sigma, 'String'));
    p.mu_m = str2double(get(f.mu_m, 'String'));
    p.C_star = str2double(get(f.C0, 'String'));
    p.tau = str2double(get(f.tau, 'String'));
    p.m_star = 0.1;
    V0 = str2double(get(f.V0, 'String'));

    % Масштаб времени
    if p.alpha == 1000, tspan = [0 80];
    elseif p.tau > 2, tspan = [0 10];
    else, tspan = [0 35];
    end

    y0 = [V0; (p.rho * p.C_star)/p.mu_f; p.C_star; 0];
    try
        sol = dde23(@(t, y, Z) marchuk_dde(t, y, Z, p), p.tau, y0, tspan);
        cla(ax);
        plot(ax, sol.x, sol.y(1,:), 'LineWidth', 2, 'Color', [0.85 0.33 0.1]);
        ylabel(ax, 'V(t)'); xlabel(ax, 't, сут'); grid(ax, 'on');
    catch ME
        errordlg(['Ошибка: ' ME.message], 'Ошибка расчета');
    end
end

function dydt = marchuk_dde(t, y, Z, p)
    V = y(1); F = y(2); C = y(3); m = y(4);
    V_tau = Z(1); F_tau = Z(2);
    if m < p.m_star, xi = 1; else, xi = max(0, (1-m)*1.1111); end
    dydt = [
        (p.beta - p.gamma * F) * V;
        p.rho * C - (p.eta * p.gamma * V + p.mu_f) * F;
        xi * p.alpha * V_tau * F_tau - p.mu_c * (C - p.C_star);
        p.sigma * V - p.mu_m * m
    ];
end
