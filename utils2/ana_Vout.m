function [Vout2, opts] = ana_Vout(Vout,opts)

% function to segment temporal components Vout into trials
% Vout2.raw contains for each stimulus type a matrix of 
%                           n_components * n_frames * n_trials
% note: baseline activity is not (although can be) subtracted from data



nb_trials = [];

for st1 = 1:opts.Nstim1
    for st2 = 1:opts.Nstim2
        nb_trials = [nb_trials, size(opts.StimTypeOrder{st1,st2},1)];
    end
end

opts.Ntrials  = min(nb_trials);


x = StimParameters();

Vout = reshape(Vout,size(Vout,1),opts.nFrames+1,[]);
Vout2 = {};
Vout2.raw = cell(opts.Nstim1, opts.Nstim2);
Vout2.mean = cell(opts.Nstim1, opts.Nstim2);
Vout2.error = cell(opts.Nstim1, opts.Nstim2);

for st1 = 1:opts.Nstim1
    for st2 = 1:opts.Nstim2
%         ind = opts.StimTypeOrder{st1,st2}(1:opts.Ntrials,1);
        ind  = find(opts.StimOrder(:,1) == x.StimID(st1,st2));
        Vout2.raw{st1,st2} = Vout(:,:,ind);
        Vout2.mean{st1,st2} = mean(Vout(:,:,ind),3);
        Vout2.error{st1,st2} = std(Vout(:,:,ind),0,3);

    end
end  
