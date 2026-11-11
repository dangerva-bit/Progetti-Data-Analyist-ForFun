% SIMULAZIONE DELL'ULTIMA PARTITA DEL MONDIALE

clc;
rng(42); 

fprintf('====================================================\n');
fprintf('  MATLAB MOTOR V24: LA FINALISSIMA (SPAGNA - ARGENTINA)\n');
fprintf('====================================================\n\n');

% --- PARAMETRI COORDINATE EXCEL ---
colonna_nazione = 4;
colonna_minuti  = 10; 
colonna_metrica = 20; % (Gol + Assist - Rigori) / 90 minuti
colonna_xGA     = 16; % Colonna dove hai messo i gol subiti dagli avversari
max_giocatori   = 14; 
partite_giocate_torneo = 6; 
fattore_tensione = 0.80; 

% --- CARICAMENTO DATASET EXCEL ---
files_da_provare = {'statistiche.xlsx - Foglio1.csv', 'statistiche.csv', 'statistiche.xlsx'};
raw_data = [];
for f = 1:length(files_da_provare)
    if isfile(files_da_provare{f})
        raw_data = readcell(files_da_provare{f}); break;
    end
end
if isempty(raw_data); fprintf('ERRORE: Nessun file Excel trovato.\n'); return; end

% --- LETTURA DATI DIFENSIVI REALI (RIGHE 4 E 5) ---
dif_spagna_raw = raw_data{4, colonna_xGA}; 
dif_argentina_raw = raw_data{5, colonna_xGA}; 

if ischar(dif_spagna_raw) || isstring(dif_spagna_raw)
    difesa_spagna = str2double(strrep(string(dif_spagna_raw), ',', '.')); 
else; difesa_spagna = double(dif_spagna_raw); end

if ischar(dif_argentina_raw) || isstring(dif_argentina_raw)
    difesa_argentina = str2double(strrep(string(dif_argentina_raw), ',', '.')); 
else; difesa_argentina = double(dif_argentina_raw); end

% Paracadute se la cella è vuota o illeggibile
if isnan(difesa_spagna) || difesa_spagna <= 0; difesa_spagna = 0.70; end
if isnan(difesa_argentina) || difesa_argentina <= 0; difesa_argentina = 0.70; end

media_torneo_subiti = 0.75; 

% Probabilità Rigori (Mantenute le tue storiche)
prob_rigore_spagna = 0.10; 
prob_rigore_argentina = 0.15; 

% --- ESTRAZIONE ROSE (PARTENDO DALLA RIGA 6) ---
team_a_eng = 'Spain'; team_b_eng = 'Argentina';
team_a_ita = 'Spagna'; team_b_ita = 'Argentina';

lambda_a = []; minuti_tot_a = []; nomi_a = [];
lambda_b = []; minuti_tot_b = []; nomi_b = [];

n_righe = size(raw_data, 1);
for r = 6:n_righe % SALTA LE PRIME 5 RIGHE
    sq_cella = raw_data{r, colonna_nazione}; 
    if isempty(sq_cella) || any(ismissing(sq_cella(:))); continue; end
    
    if ischar(sq_cella) || isstring(sq_cella)
        str_squadra = string(sq_cella);
        
        val_metrica = raw_data{r, colonna_metrica};
        if isempty(val_metrica) || any(ismissing(val_metrica(:))); metric_val = 0;
        elseif isnumeric(val_metrica); metric_val = val_metrica;
        elseif ischar(val_metrica) || isstring(val_metrica); metric_val = str2double(strrep(string(val_metrica), ',', '.')); 
        else; metric_val = 0; end
        if isnan(metric_val) || metric_val < 0; metric_val = 0; end
        
        val_m = raw_data{r, colonna_minuti};
        if isempty(val_m) || any(ismissing(val_m(:))); min_val = 0;
        elseif isnumeric(val_m); min_val = val_m;
        elseif ischar(val_m) || isstring(val_m); min_val = str2double(strrep(string(val_m), ',', '.')); 
        else; min_val = 0; end
        if isnan(min_val); min_val = 0; end
        
        nome_g = string(raw_data{r, 2});
        if isempty(nome_g) || any(ismissing(nome_g(:))); nome_g = "Sconosciuto"; end
        
        if contains(str_squadra, team_a_eng, 'IgnoreCase', true)
            lambda_a(end+1) = metric_val; minuti_tot_a(end+1) = min_val; nomi_a = [nomi_a; nome_g];
        elseif contains(str_squadra, team_b_eng, 'IgnoreCase', true)
            lambda_b(end+1) = metric_val; minuti_tot_b(end+1) = min_val; nomi_b = [nomi_b; nome_g];
        end
    end
end

% --- SELEZIONE TOP TITOLARI E DEGRADO FISICO ---
[~, idx_a] = sort(minuti_tot_a, 'descend'); taglio_a = min(max_giocatori, length(idx_a));
lambda_a = lambda_a(idx_a(1:taglio_a)); minuti_tot_a = minuti_tot_a(idx_a(1:taglio_a)); nomi_a = nomi_a(idx_a(1:taglio_a));

[~, idx_b] = sort(minuti_tot_b, 'descend'); taglio_b = min(max_giocatori, length(idx_b));
lambda_b = lambda_b(idx_b(1:taglio_b)); minuti_tot_b = minuti_tot_b(idx_b(1:taglio_b)); nomi_b = nomi_b(idx_b(1:taglio_b));

n_atleti_a = length(lambda_a); n_atleti_b = length(lambda_b);
if n_atleti_a == 0 || n_atleti_b == 0
    fprintf('ERRORE: Rose non caricate. Controlla che i giocatori partano dalla riga 6 e abbiano Spain/Argentina.\n'); return;
end

minuti_medi_a = minuti_tot_a / partite_giocate_torneo; 
minuti_medi_b = minuti_tot_b / partite_giocate_torneo;
for x = 1:n_atleti_a; lambda_a(x) = lambda_a(x) * min(1.0, minuti_medi_a(x) / 90); end
for x = 1:n_atleti_b; lambda_b(x) = lambda_b(x) * min(1.0, minuti_medi_b(x) / 90); end

for x = 1:n_atleti_a; if lambda_a(x) > 0.60; lambda_a(x) = 0.60 + ((lambda_a(x) - 0.60) * 0.25); end; end
for x = 1:n_atleti_b; if lambda_b(x) > 0.60; lambda_b(x) = 0.60 + ((lambda_b(x) - 0.60) * 0.25); end; end

% --- CALCOLO POTENZIALE OFFENSIVO CON DIFESE REALI EXCEL ---
lambda_finale_a = lambda_a * (difesa_argentina / media_torneo_subiti) * fattore_tensione;
lambda_finale_b = lambda_b * (difesa_spagna / media_torneo_subiti) * fattore_tensione;

n_scenari = 1000000;
n_fasi = 9; 
lambda_fase_a = lambda_finale_a / n_fasi;
lambda_fase_b = lambda_finale_b / n_fasi;

gol_totali_a = zeros(n_scenari, 1);
gol_totali_b = zeros(n_scenari, 1);

% --- SIMULATORE DINAMICO (GAME STATE) ---
for fase = 1:n_fasi
    mult_A = ones(n_scenari, 1);
    mult_B = ones(n_scenari, 1);
    
    idx_A_lead = gol_totali_a > gol_totali_b;
    mult_A(idx_A_lead) = 0.65; 
    mult_B(idx_A_lead) = 1.35; 
    
    idx_B_lead = gol_totali_b > gol_totali_a;
    mult_A(idx_B_lead) = 1.35; 
    mult_B(idx_B_lead) = 0.65; 
    
    if fase >= 7
        idx_tie = gol_totali_a == gol_totali_b;
        mult_A(idx_tie) = 0.80;
        mult_B(idx_tie) = 0.80;
    end
    
    for j = 1:n_atleti_a; gol_totali_a = gol_totali_a + poissrnd(lambda_fase_a(j) .* mult_A); end
    for k = 1:n_atleti_b; gol_totali_b = gol_totali_b + poissrnd(lambda_fase_b(k) .* mult_B); end
    
    prob_rig_fase_spagna = prob_rigore_spagna / n_fasi;
    prob_rig_fase_argentina = prob_rigore_argentina / n_fasi;
    
    rigore_spagna_concesso = rand(n_scenari, 1) < prob_rig_fase_spagna;
    rigore_spagna_segnato = rigore_spagna_concesso & (rand(n_scenari, 1) < 0.80); 
    gol_totali_a = gol_totali_a + rigore_spagna_segnato;
    
    rigore_argentina_concesso = rand(n_scenari, 1) < prob_rig_fase_argentina;
    rigore_argentina_segnato = rigore_argentina_concesso & (rand(n_scenari, 1) < 0.80);
    gol_totali_b = gol_totali_b + rigore_argentina_segnato;
end

% --- ANALISI STATISTICA FINALE ---
matrice_risultati = [gol_totali_a, gol_totali_b];
[risultati_unici, ~, idx_mappa] = unique(matrice_risultati, 'rows');
frequenze = accumarray(idx_mappa, 1);

totale_pesi = sum(frequenze);
v_a = 0; p = 0; v_b = 0;
for r = 1:size(risultati_unici, 1)
    g_a = risultati_unici(r, 1); g_b = risultati_unici(r, 2);
    prob = (frequenze(r) / totale_pesi) * 100;
    if g_a > g_b; v_a = v_a + prob;
    elseif g_a == g_b; p = p + prob;
    else; v_b = v_b + prob; end
end

[freq_ordinate, idx_ord] = sort(frequenze, 'descend');
ris_ord = risultati_unici(idx_ord, :);

% --- OUTPUT ---
fprintf('====================================================\n');
fprintf('   MATCH: %s VS %s (V24 LETTURA SQUADRE DA EXCEL)\n', upper(team_a_ita), upper(team_b_ita));
fprintf('====================================================\n');
fprintf(' Moduli di Precisione Applicati:\n');
fprintf('   * Metrica Input: (Gol+Assist-Rigori)/90m (Azione Manovrata)\n');
fprintf('   * Muro Difensivo (Letto da Excel): %s (%.2f xGA) | %s (%.2f xGA)\n', team_a_ita, difesa_spagna, team_b_ita, difesa_argentina);
fprintf(' Potenziale Totale Offensivo su azione (xG): %s (%.2f) vs %s (%.2f)\n\n', team_a_ita, sum(lambda_finale_a), team_b_ita, sum(lambda_finale_b));

fprintf(' Probabilità Esito Finale (1X2) nei 90 Minuti:\n');
fprintf('   * Vittoria %s (1): %.2f%%\n', team_a_ita, v_a);
fprintf('   * Pareggio     (X): %.2f%%\n', p);
fprintf('   * Vittoria %s (2): %.2f%%\n\n', team_b_ita, v_b);

fprintf(' I Risultati Esatti Rilevanti (Probabilità > 8%%):\n');
risultati_stampati = 0;
for top = 1:size(ris_ord, 1)
    p_ris = (freq_ordinate(top) / totale_pesi) * 100;
    if p_ris > 8.0 
        fprintf('   %d)  %d - %d  (Prob: %.2f%%)\n', top, ris_ord(top, 1), ris_ord(top, 2), p_ris);
        risultati_stampati = risultati_stampati + 1;
    end
end
if risultati_stampati == 0
    p_ris = (freq_ordinate(1) / totale_pesi) * 100;
    fprintf('   Nessun risultato domina nettamente. Il picco è %d - %d  (Prob: %.2f%%)\n', ris_ord(1, 1), ris_ord(1, 2), p_ris);
end
fprintf('%s\n\n', repmat('-', 1, 52));