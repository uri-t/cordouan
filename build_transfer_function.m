function [func] = build_transfer_function(input)
mats = input.materials;
geom = input.geometry;
%geom = [{'air'}, geom', {'air'}];

% add 
fprintf('propagating through:\n')
mat_list = cell(numel(geom), 1);

for ii = 1:numel(geom)
    mat = mats.(geom{ii});
    
    %% make refractive index retrieval function
    assert(isnumeric(mat.n) | ischar(mat.n), 'refractive index must be number or string')

    % static refractive index
    if isnumeric(mat.n)
        mat.n_func = @(w, n_solve) mat.n;
        
    % unknown refractive index (what we're solving for 
    elseif strcmp(mat.n, 'solve')
        mat.n_func = @(f, n_solve) n_solve;
        
    % load values for refractive
    else
        assert(isfile(mat.n),...
            'couldnt find refractive index file %s', mat.n)
        % maybe separate data load  into its own function later
        dat = importdata(mat.n);
        freq = dat(:,1);
        n = dat(:,2);
        mat.n_func = @(f, n_solve) n(freq == f);
    end
    mat_list{ii} = mat;
    fprintf('%d. %0.2f um of material w n from %s\n', ii, mat.d, mat.n)
end

c = physconst('LightSpeed')*1e6; %um/s

prop = @(freq, d, n) exp(-1i*(2*pi*freq*1e12/c)*n*d);

% should probably be something
func = @(freq, n_solve) prod(cellfun(@(m) prop(freq, m.n_func(freq, n_solve),m.d),...
    mat_list));
end