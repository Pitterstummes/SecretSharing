%%
%   Secret sharing algorihm:
%   Input a number = secret (integer <16 digits due to standart machine precision) which should be encoded
%   Input a number of participants: an equal amount of key-pairs (x,y-points) are generated
%   How many key-pairs are needed to obtain the secret (keyparcitipants)
%   The needed key-pairs uniquely define a polynomial of corresponding
%   degree, where the secret is equal to the polynomial at x=0.
%   In order to solve, use polyfit(keys_x,keys_y,polynomdegree), the last entry is the secret
%%

clc         % clear command window
close all   % closes all figures
clearvars   % remove all variables from current active workspace
warning('off') % dont print warnings

timelimit = 10; % stop execution after x seconds
counter = 0;

secretdimensions = askforsecret();
tic % start time
while true % try to find key-pairs that uniquely define the secret and reproduce it
    counter = counter + 1;
    lastwarn('', ''); % empty last warning
    keys = generate_keys(secretdimensions);
    % generate polynomial from keys and reconstruct the secret
    coeff = polyfit(keys(:,1),keys(:,2),secretdimensions.keyparticipants-1);
    guess = round(coeff(end));
    if isempty(lastwarn()) && secretdimensions.secretdouble == guess % success output
        disp([num2str(secretdimensions.participants),' keys have been successfully generated after ',num2str(counter),' iterations.'])
        disp(num2str(keys))
        disp([num2str(secretdimensions.keyparticipants),' of these keys are needed for clear encryption, ' ...
            'the polynomial is of degree ',num2str(secretdimensions.keyparticipants-1),'.'])
        % toc % print total time needed since end of dialog
        break
    end
    if toc>timelimit/(secretdimensions.secretlength-secretdimensions.range_exp) % handle  programtime
        if secretdimensions.secretlength > secretdimensions.range_exp + 1 
            secretdimensions.range_exp = secretdimensions.range_exp +1; % gradually reduce size of x-points
            secretdimensions.range_max = 2*secretdimensions.secretdouble*10^(-secretdimensions.range_exp);
        else % total timelimit is reached
            disp(['Program reached timelimit after ',num2str(counter),' iterations, choose a smaller secret!'])
            break
        end
    end
end

function resultstruct = askforsecret() % outputs a struct with secret, participants, keyparticipants and more
    % Dialog (1/3)
    prompt1     = {'Input the secret:'};
    dlgtitle1   = 'Dialog (1/3)';
    definput1   = {'1234567890'};
    % Dialog (2/3)
    prompt2     = {'Input number of participants:'};
    dlgtitle2   = 'Dialog (2/3)';
    definput2   = {'4'};
    % Dialog (3/3)
    prompt3     = {'Enter the required number of participants needed to solve for secret:'};
    dlgtitle3   = 'Dialog (3/3)';
    % Size
    fieldsize   = [1 55];
    opts.WindowStyle = 'modal';
    opts.Interpreter = 'tex';
    
    stage = 1;
    while true
        switch stage
            case 1 % Ask for secret
                secret = inputdlg(prompt1,dlgtitle1,fieldsize,definput1,opts);
                if isempty(secret)
                    stage = 0;
                elseif isnan(str2double(secret)) || ~isfinite(str2double(secret)) || str2double(secret) ~= round(str2double(secret))...
                        || strlength(secret) ~= strlength(num2str(str2double(secret)))
                    definput1 = secret;
                    prompt1 = {['Input the secret:' newline '\color{red}(Please enter an integer with < 16 digits.)']};
                else
                    stage = 2;
                end
            case 2  % Confirm secret
                answer = questdlg(['The secret you entered is:',secret],'Confirm', 'Change','Cancel','Continue','Continue');
                % Handle response
                switch answer
                    case 'Change'
                        disp('Changing secret..')
                        definput1 = secret;
                        stage = 1;
                    case 'Cancel'
                        stage = 0;
                    case 'Continue'
                        disp(['Confirmed secret to be ',char(secret),'.']);
                        stage = 3;
                    otherwise % Exit
                        stage = 0;
                end
            case 3 % Ask for number of participants
                try
                    participants = inputdlg(prompt2,dlgtitle2,fieldsize,definput2,opts);
                    disp(['Number of participants is ',char(participants),'.']);
                    participants_num = str2double(participants);
                    if ~isnan(participants_num) && isfinite(participants_num) && participants_num == round(participants_num)...
                            && strlength(participants) == strlength(num2str(participants_num))
                        stage = 4;
                    else
                        prompt2 = {['Input number of participants:' newline '\color{red}(Must be an integer number!)']};
                    end
                catch 
                    stage = 0;
                end
            case 4 % Ask for number of key participants
                try
                    keyparticipants = inputdlg(prompt3,dlgtitle3,fieldsize,participants,opts);
                    disp(['Number of keys needed to solve is ',char(keyparticipants),'.']);
                    keyparticipants_num = str2double(keyparticipants);
                    if ~isnan(keyparticipants_num) && isfinite(keyparticipants_num) && keyparticipants_num == round(keyparticipants_num)...
                            && strlength(keyparticipants) == strlength(num2str(keyparticipants_num)) && keyparticipants_num <= participants_num
                        % definitions at the end of this function
                        resultstruct.secret         = secret;
                        resultstruct.participants   = str2double(participants);
                        resultstruct.keyparticipants = str2double(keyparticipants);
                        resultstruct.secretdouble   = str2double(resultstruct.secret);
                        resultstruct.secretlength   = numel(char(resultstruct.secret));
                        resultstruct.range_exp      = round(resultstruct.secretlength/2);
                        resultstruct.range_max      = 2*resultstruct.secretdouble*10^(-resultstruct.range_exp);
                        resultstruct.range_max_coeff = resultstruct.range_max;
                        resultstruct.coefficients   = ones(1,resultstruct.keyparticipants)*resultstruct.secretdouble;
                        resultstruct.points_y       = zeros(1,resultstruct.participants);

                        return
                    else
                        prompt3 = {['Enter number of keys needed to solve for secret:' newline...
                            '\color{red}(Must be an integer number <', num2str(participants_num+1) ,'!)']};
                    end
                catch
                    stage = 0;
                end
            case 0 % Cancel program
                error('Cancelled program')
        end
    end
end

function output = generate_keys(secretdimensions) % generate random coefficients and corresponding pairs of keys
    secretdimensions.coefficients(1:end-1) = ...
        -secretdimensions.range_max_coeff + rand(1,secretdimensions.keyparticipants-1).*secretdimensions.range_max_coeff.*2;
    points_x    = 5 + rand(1,secretdimensions.participants).*(secretdimensions.range_max+5); % 5 gives save distance to the x=0 secret
    for i = 1:secretdimensions.participants
        points_x(i) = points_x(i)*(-1)^(randi(2));
        secretdimensions.points_y(i) = polyval(secretdimensions.coefficients,points_x(i));
    end
    output = horzcat(points_x',secretdimensions.points_y');
end