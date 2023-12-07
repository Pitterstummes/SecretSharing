%%
%   Secret sharing algorihm:
%   Input a number (integer) which should be the secret (secret)
%   Input a number of sharing (integer) parcitipants (parcitipants)
%   How many of the parcitipants are needed to obtain the secret (keyparcitipants)
%   The secret is the solution of a polynom at x=0, which is clear defined by keys (coordinates)
%   In order to solve, use polyfit(keys_x,keys_y,polynomdimension), the last entry is the secret
%%

clc         % clear command window
close all   % closes all figures
clearvars   % remove all variables from current active workspace
warning('off') % dont print warnings

timelimit = 10; % stop execution after x seconds
counter = 0;

secretdimensions = askforsecret();
tic
while true
    counter = counter + 1;
    lastwarn('', ''); % empty last warning
    keys = generate_keys(secretdimensions);
    secret = str2double(secretdimensions.secret);
    coeff = polyfit(keys(:,1),keys(:,2),secretdimensions.keyparticipants-1);
    guess = round(coeff(end));
    if isempty(lastwarn()) && secret == guess
        disp([num2str(secretdimensions.participants),' Keys have been successfully created after ',num2str(counter),' iterations.'])
        disp(num2str(keys))
        disp([num2str(secretdimensions.keyparticipants),' of these keys are needed for clear encryption.'])
        break
    end
    if toc>timelimit
        disp(['Program reached timelimit after ',num2str(counter),' iterations, choose a smaller secret!'])
        break
    end
end

function resultstruct = askforsecret() % outputs a struct with secret, participants and keyparticipants
    % Dialog (1/3)
    prompt1     = {'Input the secret:'};
    dlgtitle1   = 'Dialog (1/3)';
    definput1   = {'12345678'};
    % Dialog (2/3)
    prompt2     = {'Input number of participants:'};
    dlgtitle2   = 'Dialog (2/3)';
    definput2   = {'4'};
    % Dialog (3/3)
    prompt3     = {'Enter the required number of participants needed to solve for secret:'};
    dlgtitle3   = 'Dialog (3/3)';
    % Size
    fieldsize   = [1 50];
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
                    prompt1 = {['Input the secret:' newline '\color{red}(Must be an integer number!)']};
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
                    disp(['Number of participants needed to solve is ',char(keyparticipants),'.']);
                    keyparticipants_num = str2double(keyparticipants);
                    if ~isnan(keyparticipants_num) && isfinite(keyparticipants_num) && keyparticipants_num == round(keyparticipants_num)...
                            && strlength(keyparticipants) == strlength(num2str(keyparticipants_num)) && keyparticipants_num <= participants_num
                        resultstruct.secret = secret;
                        resultstruct.participants = str2double(participants);
                        resultstruct.keyparticipants = str2double(keyparticipants);
                        return
                    else
                        prompt3 = {['Enter the required number of participants needed to solve for secret:' newline...
                            '\color{red}(Must be an integer number <=', num2str(participants_num) ,'!)']};
                    end
                catch
                    stage = 0;
                end
            case 0 % Cancel program
                error('Cancelled program')
        end
    end
end

function output = generate_keys(secretdimensions)
    scaler      = 2*str2double(secretdimensions.secret);
    secretlen   = round(numel(char(secretdimensions.secret))/2);
    coeff_max   = scaler*10^(-secretlen);
    coefficients = -coeff_max + rand(1,secretdimensions.keyparticipants).*coeff_max.*2;
    coefficients(end) = scaler/2;
    points_max  = scaler*10^(-secretlen);
    points_x    = -points_max + rand(1,secretdimensions.participants).*points_max.*2;
    points_y    = zeros(1,secretdimensions.participants);
    for i = 1:secretdimensions.participants
        points_y(i) = polyval(coefficients,points_x(i));
    end
    output = horzcat(points_x',points_y');
end