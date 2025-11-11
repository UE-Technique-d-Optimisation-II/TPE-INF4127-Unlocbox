%% =========================================================================
% TUTORIEL UNLOCBOX - INPAINTING D'IMAGE (VERSION CORRIGÉE)
% Cours INF4127 - Université de Yaoundé I
% =========================================================================

% Vérification de l'installation
if ~exist('solvep', 'file')
    error('UNLocBoX non installé. Ajoutez-le au chemin MATLAB.');
end

close all; clear; clc;

fprintf('=== DÉMARRAGE DU TUTORIEL UNLOCBOX ===\n\n');

%% ÉTAPE 1 : PRÉPARATION
fprintf('1. Chargement de l''image...\n');
y_original = im2double(imread('clock_256.gif'));

figure('Position', [100 100 400 400]);
imshow(y_original); title('Image originale'); colormap gray;
pause(1);

%% ÉTAPE 2 : MASQUE
fprintf('2. Création du masque...\n');
rng(42);
mask = rand(size(y_original)) > 0.5;

figure('Position', [550 100 400 400]);
imshow(mask); title('Masque'); colormap gray;
pause(1);

%% ÉTAPE 3 : APPLICATION
fprintf('3. Application du masque...\n');
A = @(x) mask .* x; At = A;
y_corrompue = A(y_original);

figure('Position', [1000 100 400 400]);
imshow(y_corrompue); title('Image masquée'); colormap gray;
pause(1);

%% ÉTAPE 4 : DÉFINITION DES FONCTIONS
fprintf('4. Définition des fonctions...\n');

lambda = 0.1;
f1 = struct();
f1.eval = @(x) norm(A(x) - y_corrompue, 'fro')^2 / 2;
f1.grad = @(x) At(A(x) - y_corrompue);
f1.beta = 1;

f2 = struct();
f2.eval = @(x) lambda * norm_tv(x);
f2.prox = @(x,T) prox_tv(x, lambda*T);

fprintf('   Lambda = %.2f, Beta = %.2f\n', lambda, f1.beta);

%% ÉTAPE 5 : CONFIGURATION DU SOLVEUR
fprintf('5. Configuration du solveur...\n');

param = struct();
param.verbose = 1;
param.maxit = 500;  % AUGMENTÉ pour assurer la convergence
param.tol = 1e-4;
param.min_round = 10;
param.acceleration = 1;

fprintf('   Max iterations = %d\n', param.maxit);

%% ÉTAPE 6 : RÉSOLUTION
fprintf('\n6. Démarrage de la reconstruction...\n');

tic;
% ESSAYER AVEC DIFFÉRENTES SYNTAXES
try
    % Syntaxe moderne (param.solver)
    param.solver = 'fista';
    [sol, info] = solvep(y_corrompue, {f1, f2}, param);
catch
    % Syntaxe ancienne (4ème argument)
    try
        [sol, info] = solvep(y_corrompue, {f1, f2}, param, 'fista');
    catch
        % Fallback : sans spécifier le solveur
        fprintf('   ⚠ Utilisation du solveur par défaut...\n');
        [sol, info] = solvep(y_corrompue, {f1, f2}, param);
    end
end
temps = toc;

fprintf('   Terminé en %.2f secondes\n', temps);

%% DÉBOGAGE : AFFICHER LES CHAMPS DISPONIBLES
fprintf('\n=== DÉBOGAGE ===\n');
fprintf('Champs dans info : %s\n', strjoin(fieldnames(info), ', '));

%% ÉTAPE 7 : VISUALISATION
fprintf('\n7. Affichage des résultats...\n');

mse = mean((sol(:) - y_original(:)).^2);
psnr = 10*log10(1/mse);

figure('Position', [100 100 1400 500]);
subplot(1,4,1); imshow(y_original); title('Originale'); colormap gray;
subplot(1,4,2); imshow(y_corrompue); title('Masquée'); colormap gray;
subplot(1,4,3); imshow(sol, []); title(sprintf('Restaurée\nPSNR: %.2f dB', psnr)); colormap gray;
subplot(1,4,4); imshow(abs(sol - y_original), []); title('Erreur'); colormap gray; colorbar;

%% ÉTAPE 8 : COURBE DE CONVERGENCE

% TROUVER LE CHAMP DE COÛT AUTOMATIQUEMENT
if isfield(info, 'cost')
    cout = info.cost;
    champ = 'cost';
elseif isfield(info, 'fun')
    cout = info.fun;
    champ = 'fun';
elseif isfield(info, 'f')
    cout = info.f;
    champ = 'f';
else
    % Chercher un champ vectoriel
    champs = fieldnames(info);
    for i = 1:length(champs)
        if isa(info.(champs{i}), 'double') && isvector(info.(champs{i}))
            cout = info.(champs{i});
            champ = champs{i};
            break;
        end
    end
end

if exist('cout', 'var') && length(cout) > 1
    fprintf('Champ de coût utilisé : %s\n', champ);
    figure('Position', [100 600 800 400]);
    plot(cout, 'b-', 'LineWidth', 2);
    xlabel('Itération'); ylabel('Coût');
    title(sprintf('Convergence (%s)', champ)); grid on;
else
    fprintf('Aucun champ de coût trouvé pour tracer la courbe.\n');
end

%% RÉSULTATS
fprintf('\n=== RÉSULTATS ===\n');
fprintf('PSNR : %.2f dB\n', psnr);
fprintf('Temps : %.2f s\n', temps);
fprintf('Itérations : %d\n', info.iter);

fprintf('\n=== FIN DU TUTORIEL ===\n');*************************