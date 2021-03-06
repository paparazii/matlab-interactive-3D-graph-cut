%% Ukazka segmentace pomoci Grapg-Cut s pevnymi uzly, N-linky konst.
% Oznacene pixely jsou pouzty pro modelovani barvy objektu a pozadi. Jsou
% nastaveny pevna spojeni s uzly. T-linky jsou nastaveny pomoci
% pravdepodobnostnich modelu, N-linky jsou nastaveny konstantne.

%% Cesty k externim zdroju
clear, clc, close

% Cesta ke GMM - nástroj pro modelování gaussovských směsí
%     http://lasa.epfl.ch/sourcecode/index.php
addpath('../outsource/gmm/');


% Cesta k matlab wrapperu C funkce graph-cut 
% Implementace gc v jazyce C
%     http://www.csd.uwo.ca/~olga/code.html
% Matlab wrapper
%     http://vision.ucla.edu/~brian/gcmex.html
addpath('../outsource/gc_veksler/');
addpath('../gauss_tools/');
addpath('../gui_tools/');

%% Nacteni dat
img = imread('cameraman.tif');
% img = imread('peppers.png');
% img = imread('canoe.tif');
% img = imread('football.jpg');
%  img = imread('office_6.jpg');
%  img = imread('pillsetc.png');
% img = imread('pears.png');

img = im2double(img);

fig = figure(1);
imshow(img);
nghb = 4;


%% Oznaceni seedu
% spusteni oznacovaci funkce
% parametry jsou cislo fgury a velikost okoli
% zacina se kreslit kliknutim, konci se dalsim kliknutim
% oSeeds a bSeeds jsou seznamy bodu oznacenych pravym a levym mysitkem
[oSeeds, bSeeds oSeedsIm, bSeedsIm] = markSeeds(fig, nghb);


%% Tvorba modelu
oS = double(selectPoints(img, oSeeds(1,:), oSeeds(2,:)));
bS = double(selectPoints(img, bSeeds(1,:), bSeeds(2,:)));

% tohle jen ukaze stredni hodnotu z vybranych oblasti

oModel = create_model(oS',2);
bModel = create_model(bS',2);

siz = size(img);

% % osetreni RGB
% if(length(siz) == 3)
%     imgV = reshape(img, siz(1)*siz(2), siz(3));
% else
%     imgV = reshape(img, siz(1)*siz(2), 1);
% end

imgV = reshape(img, siz(1)*siz(2),[]);

oProbV = gaussK(double(imgV)', oModel.priors, oModel.mu, oModel.sigma);
bProbV = gaussK(double(imgV)', bModel.priors, bModel.mu, bModel.sigma);

oProb = reshape (oProbV, siz(1), siz(2));
bProb = reshape (bProbV, siz(1), siz(2));

seg0 = oProb > bProb;

%% Vypocet vah N-linku
% vypocet vah
% lambda = 37.8;
lambda = 30.0;
Sc = [ 0, lambda; lambda,0];
K = lambda*4+1;
K = 200;

%% Vypocet vah T-linku
oProbLog = log(oProb+1e-50);
bProbLog = log(bProb+1e-50);

% nejmensi minimum, aby to bylo kladne, ale odecitalo se porad stejne
minoffset  = min(min(oProbLog(:)), min(bProbLog(:)));
oProbLog = oProbLog - minoffset;
bProbLog = bProbLog - minoffset;

% pevne spojeni s s a t
% nastavime nuly tam kde jsou pixely oznaceny
oProbLog = oProbLog .* (1 - oSeedsIm) .* (1 - bSeedsIm);
bProbLog = bProbLog .* (1 - bSeedsIm) .* (1 - oSeedsIm);
objW = oProbLog + K.*oSeedsIm;
bckW = bProbLog + K.*bSeedsIm;

Dc = cat(3, objW,bckW );

%% Vypocet rezu grafem
gch = GraphCut( 'open', Dc, Sc );
[gch L] = GraphCut( 'expand', gch );
gch = GraphCut( 'close', gch );


%% Vykresleni vysledku
% nove vykresleni obrazku - je tak videtkolik se toho nacetlo

% jako co je nas obrazek
label = 1;

lb=(L==label) ;
lb=imdilate(lb,strel('disk',1))-lb ; 
hold on; contour(lb,[1 1],'g') ; hold off ;
