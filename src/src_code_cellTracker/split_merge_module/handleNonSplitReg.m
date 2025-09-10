function [movieInfo, merge_regs] = handleNonSplitReg(movieInfo, ...
    reg4split, baseReg, g)
% if the region can not be split, see if 
% case 1: link only one of its kids/parents
% case 2: directly merge its kids/parents

merge_regs = [];

goodNeiFlag = false;
for i=1:length(baseReg)
    [found_aCandid, cost] = bestCijPair(movieInfo, reg4split, baseReg(i));
    if found_aCandid
        if cost < abs(g.observationCost)
            baseReg(i) = nan;
            % these two functions are similar, but it is better not to
            % remove directly the relationship
            % way 1
            % movieInfo = removeCellRelation(movieInfo, reg4split, baseReg);
            % way 2
            movieInfo = infinitifyCellRelation(movieInfo, reg4split, baseReg);
            goodNeiFlag = true;
        end
        break;
    end
end
if ~goodNeiFlag
    merge_regs = baseReg;
end

end