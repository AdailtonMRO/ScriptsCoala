instrument {
    name = 'CoalaV22_Final',
    short_name = 'Coala Max',
    icon = 'indicators:AO',
    overlay = true
}

-- ==== CONFIGURAES INICIAIS ==== --
mercado_modo = input(1, "Modo de Mercado", input.string_selection, {"Normal (Retracao)", "OTC (Rompimento/Fluxo)"})
local is_otc = (mercado_modo == 2)

exibir_linhas = input(1, "Exibir as Linhas de SeR?", input.string_selection, {"SIM", "NAO"})

input_group {"BUY",buy_color = input {default = "lime", type = input.color}}
input_group {"SELL",sell_color = input { default = "red", type = input.color }}

-- NOVO MENU: ESTRATGIA FLASH M1
input_group {
    "Estrategia Flash M1",
    usar_flash = input(1, "Ativar Flash M1?", input.string_selection, {"SIM", "NAO"}),
    bb_periodo = input(20, "Periodo Bollinger", input.integer, 5, 100),
    bb_desvio = input(2.5, "Desvio Bollinger", input.double, 1.0, 5.0),
    rsi_rapido_per = input(5, "Periodo RSI Rapido", input.integer, 2, 50)
}

input_group {
    "MACD",
    fast = input (7, "MACD fast period", input.integer, 1, 250),
    slow = input (13, "MACD slow period", input.integer, 1, 250),
    signal_period = input (5, "MACD signal period", input.integer, 1, 250),
}

input_group {
    "Stockhastic",
    k_period = input (7, "Stockhastic period K", input.integer, 1),
    d_period = input (3, "Stockhastic period D", input.integer, 1),
    smooth = input (3, "Stockhastic smoothing", input.integer, 1),
    overboughtZone = input (80, "Stockhastic overbought", input.integer, 1),
    oversoldZone = input (20, "Stockhastic oversold", input.integer, 1),
}

percentage = input (5, "Forca do GAP", input.double, 0.01, 100, 1.0) / 1000
    source = input (1, "front.ind.source", input.string_selection, inputs.titles_overlay)
    fn = input (averages.ema, "front.newind.average", input.string_selection, averages.titles)
    
    local sourceSeries = inputs [source]
    local averageFunction = averages [fn]
    
    -- ==== LINHAS DE S&R ==== --
    r10 = highest(15)[1]
    s10 = lowest(15)[1]
    r30 = highest(30)[1]
    s30 = lowest(30)[1]
    r60 = highest(60)[1]
    s60 = lowest(60)[1]
    r100 = highest(100)[1]
    s100 = lowest(100)[1]
    r150 = highest(150)[1]
    s150 = lowest(150)[1]
    r200 = highest(200)[1]
    s200 = lowest(200)[1]
    
    if exibir_linhas == 1 then
        hline(r10,"HH10","rgba(7, 243, 247, 0.3)",1)
        hline(s10,"LL10","rgba(7, 243, 247, 0.3)",1)
        hline(r30,"HH30","rgba(7, 243, 247, 0.4)",1)
        hline(s30,"LL30","rgba(7, 243, 247, 0.4)",1)
        hline(r60,"HH60","rgba(7, 243, 247, 0.5)",1)
        hline(s60,"LL60","rgba(7, 243, 247, 0.5)",1)
        hline(r100,"HH100","rgba(7, 243, 247, 0.6)",1)
        hline(s100,"LL100","rgba(7, 243, 247, 0.6)",1)
        hline(r150,"HH150","rgba(7, 243, 247, 0.7)",1)
        hline(s150,"LL150","rgba(7, 243, 247, 0.7)",1)
        hline(r200,"HH200","rgba(7, 243, 247, 0.9)",1) 
        hline(s200,"LL200","rgba(7, 243, 247, 0.9)",1)
    end
    
    -- == GAP E S&R AVISOS == --
    GAPPER = (((abs(open - close[1]))/close[1])*1000) > percentage
    local desvio_rapido = stdev(hl2,3)
    dist_s = min(abs(close[1]-s10),abs(close[1]-s30),abs(close[1]-s60),abs(close[1]-s100),abs(close[1]-s150),abs(close[1]-s200))
    dist_r = min(abs(close[1]-r10),abs(close[1]-r30),abs(close[1]-r60),abs(close[1]-r100),abs(close[1]-r150),abs(close[1]-r200))
    dist_sr = iff(dist_s <= dist_r,dist_s,dist_r)
    
    SeRSuporte = dist_s < desvio_rapido
    SeRResistencia = dist_r < desvio_rapido
    
    if (dist_sr < desvio_rapido) then 
        plot_candle (open, high, low, close, "ES", "rgba(255, 255, 224, 0.5)")
    end
    
    -- ===== MEDIAS E OSCILADORES ==== --
    fastSSMA = ssma(close[1], fast)
    mediumSSMA = ssma(close[1], slow)
    slowSSMA = ssma(close[1], 200)
    RSI = rsi(close[1], fast)
    
    plot (fastSSMA, "EMA 1", "rgba(0, 255, 0, 0.3)" , 2)
    plot (mediumSSMA, "EMA 2", "rgba(255, 0, 0, 0.3)", 2)
    plot (slowSSMA, "EMA 3", "rgba(255, 255, 0, 0.3)", 2)
    
    -- Lgica de Velas
    Shadow_a = (high[1] - low[1])
    Body_a = (abs(close[1] - open[1]))
    Shadow_b = (high[2] - low[2])
    Body_b = (abs(close[2]-open[2]))
    Shadow_c = (high[3]-low[3])
    Body_c = (abs(close[3]-open[3]))
    MidCandleBody_a = abs(close[1] + open[1])/2
    
    -- MACD
    fastMA = averageFunction(close[1], 3)
    slowMA = averageFunction(close[1], 7)
    macd = fastMA - slowMA
    signal = averageFunction(macd, 2)
    macdIsBUY = macd > signal
    macdIsSELL = macd < signal
    
    -- STK
    k = sma (stochastic (close[1], k_period), smooth) * 100
    d = sma (k, d_period)
    stkIsTop = k > overboughtZone
    stkIsBottom = k < oversoldZone
    stkIsSELL = false
    stkIsBUY = false
    
    if stkIsTop and k < overboughtZone and d < overboughtZone and k < d then stkIsSELL = true end
    if stkIsBottom and k > oversoldZone and d > oversoldZone and k > d then stkIsBUY = true end
    if stkIsSELL == true and k > d then stkIsSELL = false end
    if stkIsBUY == true and k < d then stkIsBUY = false end
    
    -- CLCULOS DO FLASH M1 (Bollinger + RSI Rpido)
    basis = sma(close[1], bb_periodo)
    dev = stdev(close[1], bb_periodo) * bb_desvio
    upperBB = basis + dev
    lowerBB = basis - dev
    linha_rsi_rapida = rsi(close[1], rsi_rapido_per)
    
    tamanho_corpo = abs(open[1] - close[1])
    tamanho_total = high[1] - low[1]
    vela_tem_forca = tamanho_corpo > (tamanho_total * 0.5)
    
    is_flash_buy = (close[1] < lowerBB) and (linha_rsi_rapida < 15) and (close[1] < open[1]) and vela_tem_forca
    is_flash_sell = (close[1] > upperBB) and (linha_rsi_rapida > 85) and (close[1] > open[1]) and vela_tem_forca
    
    if usar_flash == 1 then
        plot(upperBB, "BB Sup", "rgba(255, 255, 255, 0.2)", 1)
        plot(lowerBB, "BB Inf", "rgba(255, 255, 255, 0.2)", 1)
    end
    
    -- S&R MTF LGICA
    percentage2 = input (5, "Percentage SeR", input.double, 0.01, 100, 1.0) / 100
    local reference = make_series ()
    reference:set(nz(reference[1], highest(high, 3)))
    local is_direction_up = make_series ()
    is_direction_up:set(nz(is_direction_up[1], true))
    local htrack = make_series ()
    local ltrack = make_series ()
    local pivot = make_series ()
    reverse_range = reference * percentage2 / 100
    
    if get_value (is_direction_up) then
        htrack:set (max(high, nz(htrack[1], high)))
        if close < htrack[1] - reverse_range then
            pivot:set (htrack)
            is_direction_up:set (false)
            reference:set(htrack)
            up = false
        end
    else
        ltrack:set (min(low, nz(ltrack[1], low)))
        if close > ltrack[1] + reverse_range then
            pivot:set (ltrack)
            is_direction_up:set(true)
            reference:set (ltrack)
            up = true
        end
    end
    
    x = fixnan(pivot)
    count = 0
    mytable = { 0,0,0,0,0 }
    for i=1,220,1 do
        if x[i] ~= x[i+1] then
            found = false
            for j=1,5,1 do
                if (x[i] < (mytable[j] + 0.0005)) and (x[i] > (mytable[j] - 0.0005)) then found = true end
            end
            if found ~= true then
                count = count + 1
                table.insert(mytable,count,x[i])
            end
        end
        if count == 5 then break end
    end
    
    Weight = 1
    UPscore = 0
    DOWNscore = 0
    
    -- ESTRATEGIA 1 -- S&R
    for z=1,5 do
        if close[1] < mytable[z] and abs(close[1] - mytable[z]) < desvio_rapido then
            if is_otc then UPscore = UPscore + Weight else DOWNscore = DOWNscore - Weight end
        end
        if close[1] > mytable[z] and abs(close[1] - mytable[z]) < desvio_rapido then
            if is_otc then DOWNscore = DOWNscore - Weight else UPscore = UPscore + Weight end
        end
    end
    
    -- ESTRATEGIA 2 A 16 -- TENDENCIAS E OSCILADORES
    if up==true then UPscore = UPscore + Weight*2 else DOWNscore = DOWNscore - Weight*2 end
    if ((fastSSMA[1]>fastSSMA[2]) and (fastSSMA[2]>fastSSMA[3]) and (fastSSMA[3]>fastSSMA[4])) then UPscore = UPscore + 2*Weight end
    if ((fastSSMA[1]<fastSSMA[2]) and (fastSSMA[2]<fastSSMA[3]) and (fastSSMA[3]<fastSSMA[4])) then DOWNscore = DOWNscore - 2*Weight end
    if ((mediumSSMA[1]>mediumSSMA[3]) and (mediumSSMA[3]>mediumSSMA[5]) and (mediumSSMA[5]>mediumSSMA[7])) then UPscore = UPscore + 1*Weight end
    if ((mediumSSMA[1]<mediumSSMA[3]) and (mediumSSMA[3]<mediumSSMA[5]) and (mediumSSMA[5]<mediumSSMA[7])) then DOWNscore = DOWNscore - 1*Weight end
    if ((slowSSMA[1]>slowSSMA[5]) and (slowSSMA[5]>slowSSMA[10]) and (slowSSMA[10]>slowSSMA[15])) then UPscore = UPscore + 0.5*Weight end
    if ((slowSSMA[1]<slowSSMA[5]) and (slowSSMA[5]<slowSSMA[10]) and (slowSSMA[10]<slowSSMA[15])) then DOWNscore = DOWNscore - 0.5*Weight end
    
    if is_otc then
        if RSI > overboughtZone then UPscore = UPscore + Weight*2 end 
        if RSI < oversoldZone then DOWNscore = DOWNscore - Weight*2 end
    else
        if RSI > overboughtZone+10 then DOWNscore = DOWNscore - Weight end
        if RSI < oversoldZone-10 then UPscore = UPscore + Weight end
        if RSI > overboughtZone then DOWNscore = DOWNscore - Weight end
        if RSI < oversoldZone then UPscore = UPscore + Weight end
    end
    
    if stkIsBUY == true then UPscore = UPscore + Weight end
    if stkIsSELL == true then DOWNscore = DOWNscore - Weight end
    if macdIsBUY == true then UPscore = UPscore + Weight end
    if macdIsSELL == true then DOWNscore = DOWNscore - Weight end
    if SeRSuporte == true then if is_otc then DOWNscore = DOWNscore - 2*Weight else UPscore = UPscore + 2*Weight end end
    if SeRResistencia == true then if is_otc then UPscore = UPscore + 2*Weight else DOWNscore = DOWNscore - 2*Weight end end
    
    -- =======================================================
    -- ESTRATEGIAS 17 A 28 -- PRICE ACTION (FILTRADO POR S&R)
    -- =======================================================
    
    -- 1. Define as variveis das velas (Mantido)
    is_3_withe_soldier = close[1] > open[1] and close[2] > open[2] and close[3] > open[3] and close[4] < open[4] and Body_a > Shadow_a*0.4 and Body_b > Shadow_b*0.4 and Body_c > Shadow_c*0.4
    is_3_black_crows = close[1] < open[1] and close[2] < open[2] and close[3] < open[3] and close[4] > open[4] and Body_a > Shadow_a*0.4 and Body_b > Shadow_b*0.4 and Body_c > Shadow_c*0.4
    enfulfingdn = (close[2] > open[2]) and (close[1] < open[1]) and (close[1] < open[2]) and (close[2] <= open[1])
    is_dark_cloud = close[2] > open[2] and Body_b > Shadow_b*0.7 and close[1] < open[1] and Body_a > Shadow_a*0.7 and open[1] > close[2] and open[2] < close[1] and close[1] < MidCandleBody_a 
    is_hammer = (open[1] < close[1] and close[1] > high[1] - (Shadow_a * 0.05) and Body_a <= (Shadow_a * 0.4) and Body_a > (Shadow_a * 0.2)  )
    is_hangingMan = (open[1] > close[1] and open[1] > high[1] - (Shadow_a * 0.05) and Body_a <= (Shadow_a * 0.4) and Body_a > (Shadow_a * 0.2)  )
    is_bear_harami = (close[2] > open[2] and open[1] > close[1] and open[1] <= close[2] and open[2] <= close[1] and open[1] - close[1] < close[2] - open[2] and open[1] < close[2] )
    engulfingup = (close[2] < open[2]) and (close[1] > open[1]) and (close[1] > open[2]) and (close[2] >= open[1])
    is_piercing   = close[2] < open[2] and Body_b > Shadow_b*0.7 and close[1] > open[1] and Body_a > Shadow_a*0.7 and open[1] < close[2] and close[1] < open[2] and close[1] > MidCandleBody_a 
    is_inverted_hammer = (open[1] < close[1] and open[1] < low[1] + (Shadow_a * 0.05) and Body_a <= (Shadow_a * 0.4) and Body_a > (Shadow_a * 0.2)  )
    is_shottingStar = (open[1] > close[1] and close[1] < low[1] + (Shadow_a * 0.05) and Body_a <= (Shadow_a * 0.4) and Body_a > (Shadow_a * 0.2)  )
    is_bull_harami = (close[2] < open[2] and open[1] < close[1] and open[1] >= close[2] and open[2] >= close[1] and open[1] - close[1] >close[2] - open[2] and open[1] > close[2] )
    
    -- 2. Define as Zonas Vlidas com base no Modo de Mercado
    local zona_PA_compra = false
    local zona_PA_venda = false
    
    if is_otc then
        -- Modo OTC: Aposta no Rompimento
        zona_PA_compra = SeRResistencia
        zona_PA_venda = SeRSuporte
    else
        -- Modo Normal: Aposta na Retrao
        zona_PA_compra = SeRSuporte
        zona_PA_venda = SeRResistencia
    end
    
    -- 3. Aplica a Pontuao APENAS se estiver na Zona Vlida
    if zona_PA_compra then
        if is_3_withe_soldier then UPscore = UPscore + 2*Weight end 
        if is_hammer then UPscore = UPscore + 3*Weight end 
        if engulfingup then UPscore = UPscore + 2*Weight end
        if is_piercing then UPscore = UPscore + 2*Weight end
        if is_inverted_hammer then UPscore = UPscore + 2*Weight end
        if is_bull_harami then UPscore = UPscore + 2*Weight end
    end
    
    if zona_PA_venda then
        if is_3_black_crows then DOWNscore = DOWNscore - 2*Weight end 
        if enfulfingdn then DOWNscore = DOWNscore - 2*Weight end
        if is_dark_cloud then DOWNscore = DOWNscore - 2*Weight end
        if is_hangingMan then DOWNscore = DOWNscore - 2*Weight end
        if is_bear_harami then DOWNscore = DOWNscore - 2*Weight end
        if is_shottingStar then DOWNscore = DOWNscore - 3*Weight end 
    end
    
    -- Zera doji
    if ((abs(open[1] - close[1])) <= (0.1 * abs(high[1] - low[1]))) then
        DOWNscore = 0
        UPscore = 0
    end
    
    -- ESTRATGIA 29 -- INTEGRAO M1 FLASH (Garante o peso 4 para acionar o sinal)
    if usar_flash == 1 then
        if is_flash_buy then UPscore = UPscore + 4 * Weight end
        if is_flash_sell then DOWNscore = DOWNscore - 4 * Weight end
    end
    
    -- ==================== PLOTAGEM DOS SINAIS ==================== --
    local PontuacaoLiquida = UPscore + DOWNscore 
    local GatilhoForte = 5
    
    --if GAPPER then plot_shape(1, 'Wait', shape_style.cross, shape_size.normal, "#FFFFFF", shape_location.bottom, 0, "GAP", "#FFFFFF") end
    
    -- Radar
    if PontuacaoLiquida > 0 and PontuacaoLiquida < GatilhoForte then
        plot_shape(1, 'RadarC', shape_style.circle, shape_size.normal, "rgba(255, 255, 0, 0.4)", shape_location.belowbar, 0, "+"..PontuacaoLiquida, "yellow")
    end
    if PontuacaoLiquida < 0 and PontuacaoLiquida > -GatilhoForte then
        plot_shape(1, 'RadarV', shape_style.circle, shape_size.normal, "rgba(255, 165, 0, 0.4)", shape_location.abovebar, 0, tostring(PontuacaoLiquida), "orange")
    end
    
    -- Sinais Fortes Oficiais
    if PontuacaoLiquida <= -GatilhoForte then
        local texto_venda = "Venda ("..PontuacaoLiquida..")"
        if is_otc then texto_venda = "OTC Venda ("..PontuacaoLiquida..")" end
        if usar_flash == 1 and is_flash_sell then texto_venda = "FLASH Venda" end
        
        plot_shape(1, 'Venda', shape_style.arrowdown, shape_size.huge, "red", shape_location.abovebar, 0, texto_venda, "#FFFFFF")
    end
    
    if PontuacaoLiquida >= GatilhoForte then
        local texto_compra = "Compra ("..PontuacaoLiquida..")"
        if is_otc then texto_compra = "OTC Compra ("..PontuacaoLiquida..")" end
        if usar_flash == 1 and is_flash_buy then texto_compra = "FLASH Compra" end
        
        plot_shape(1, 'Compra', shape_style.arrowup, shape_size.huge, "green", shape_location.belowbar, 0, texto_compra, "#FFFFFF") 
    end
    -- ============================================================== --
    
    -- SUPORTE E RESISTENCIA MTF
    candle_time = {"1s", "5s", "10s", "15s", "30s", "1m", "2m", "5m", "10m", "15m", "30m", "1H", "2H", "4H", "8H", "12H", "1D", "1W", "1M", "1Y"}
    candle_time_res = input(10,"Candle check resolution",input.string_selection,candle_time)
    method_id = input (2, "Type", input.string_selection, { "SR" })
    
    input_group {
        "Maxima",
        level_1_color = input { default = "#FF0000", type = input.color },
        level_1_width = input { default = 2, type = input.line_width }
    }
    input_group {
        "Minima",
        level_2_color = input { default = "#32CD32", type = input.color },
        level_2_width = input { default = 2, type = input.line_width }
    }
    
    local function SeR(candle) c1 = candle.high c2 = candle.low end
    local methods = { SeR }
    
    sec = security (current_ticker_id, candle_time[candle_time_res])
    if sec then
        local method = methods [method_id]
        method (sec)
        if exibir_linhas == 1 then
            plot (c1, "C1",   level_1_color, level_1_width, 0, style.levels, na_mode.continue)
            plot (c2, "C2",   level_2_color, level_2_width, 0, style.levels, na_mode.continue) 
        end
    end
