% =========================================================================
% SCRIPT MATLAB: ROSA IDEALE (FOCUS SUI BONUS E SULL'EFFICIENZA)
%% Script per trovare i giocatori a rendimento maggiore e che portano più
%% punti
clc; close all;

fprintf('=========================================================\n');
fprintf('  AVVIO ESTRAZIONE ROSA IDEALE (PESO MASSIMO AI BONUS)\n');
fprintf('=========================================================\n');

% Selezione manuale del file tramite finestra
[file_name, path_name] = uigetfile('*.xlsx', 'Seleziona il file di Statistiche Fantacalcio');
if isequal(file_name, 0)
    error('Selezione annullata dall''utente.');
end
filename = fullfile(path_name, file_name);

% Lettura sicura del foglio 'Tutti' saltando la prima riga di titolo
data_raw = readtable(filename, 'Sheet', 'Tutti', 'HeaderLines', 1);

num_rows = height(data_raw);
fprintf('File caricato con successo. Giocatori totali: %d\n', num_rows);

% Estrazione colonne chiave
Ruoli = string(data_raw.R);
Presenze = data_raw.Pv;
Fantamedia = data_raw.Fm;
Gol = data_raw.Gf;
Assist = data_raw.Ass;

% Pulizia dei valori NaN
Presenze(isnan(Presenze)) = 0;
Fantamedia(isnan(Fantamedia)) = 0;
Gol(isnan(Gol)) = 0;
Assist(isnan(Assist)) = 0;

% CALCOLO DELL'INDICE: PRIVILEGIAMO L'EFFICIENZA E I BONUS PESANTI
IndiceAppetibilita = zeros(num_rows, 1);

for i = 1:num_rows
    pv = Presenze(i);
    fm = Fantamedia(i);
    gf = Gol(i);
    ass = Assist(i);
    
    % Coefficiente di presenza flessibile: 
    % - Sotto le 12 presenze scatta una penalità progressiva (per evitare chi ha giocato 2 partite).
    % - Sopra le 12 presenze il freno si allenta e lascia spazio alla forza bruta dei bonus.
    if pv < 12
        fattore_presenze = (pv / 12) ^ 1.5;
    else
        fattore_presenze = min(0.7 + (pv / 38) * 0.3, 1.0); % Premia la presenza ma non penalizza chi ha fatto 30 anziché 38
    end
    
    % MOTORE DEL PUNTEGGIO:
    % Diamo un peso massiccio a Gol e Assist reali, sommati alla fantamedia, 
    % moltiplicati per il fattore di presenza flessibile.
    punteggio_base = (fm * pv) + (gf * 12.0) + (ass * 7.0); 
    
    IndiceAppetibilita(i) = punteggio_base * fattore_presenze;
end

data_raw.IndiceAppetibilita = IndiceAppetibilita;

% Normalizzazione in scala 0-100
min_val = min(IndiceAppetibilita);
max_val = max(IndiceAppetibilita);
if max_val > min_val
    data_raw.Indice100 = round(((IndiceAppetibilita - min_val) / (max_val - min_val)) * 100, 1);
else
    data_raw.Indice100 = zeros(num_rows, 1);
end

% Target richiesti per l'asta
target_P = 9;   % Portieri
target_D = 24;  % Difensori
target_C = 24;  % Centrocampisti
target_A = 18;  % Attaccanti

% Filtro e ordinamento rigoroso per reparto (dal più alto al più basso)
is_p = (Ruoli == 'P');
is_d = (Ruoli == 'D');
is_c = (Ruoli == 'C');
is_a = (Ruoli == 'A');

T_p = sortrows(data_raw(is_p, :), 'IndiceAppetibilita', 'descend');
T_d = sortrows(data_raw(is_d, :), 'IndiceAppetibilita', 'descend');
T_c = sortrows(data_raw(is_c, :), 'IndiceAppetibilita', 'descend');
T_a = sortrows(data_raw(is_a, :), 'IndiceAppetibilita', 'descend');

if height(T_p) > target_P, T_p = T_p(1:target_P, :); end
if height(T_d) > target_D, T_d = T_d(1:target_D, :); end
if height(T_c) > target_C, T_c = T_c(1:target_C, :); end
if height(T_a) > target_A, T_a = T_a(1:target_A, :); end

RosaIdeale = [T_p; T_d; T_c; T_a];

% Salvataggio del file finale
output_file = fullfile(path_name, 'rosa_ideale_asta_bonus.xlsx');
writetable(RosaIdeale, output_file);

fprintf('\n=========================================================\n');
fprintf('  ROSA IDEALE SULLA POTENZA DEI BONUS ESTRATTA CON SUCCESSO!\n');
fprintf('  - Portieri selezionati: %d\n', height(T_p));
fprintf('  - Difensori selezionati: %d\n', height(T_d));
fprintf('  - Centrocampisti selezionati: %d\n', height(T_c));
fprintf('  - Attaccanti selezionati: %d\n', height(T_a));
fprintf('  File salvato in: -> %s\n', output_file);
fprintf('=========================================================\n');