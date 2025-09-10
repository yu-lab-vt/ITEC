function [flag, cost] = bestCijPair(movieInfo, id1, id2)
% find if id1 and id2 are the nereast neighbors to each other in the
% corresponding frames

flag = false;

f1 = movieInfo.frames(id1);
f2 = movieInfo.frames(id2);
cost = nan;
if f1 == f2
    return;
end
if f1>f2
    id = id1;
    id1 = id2;
    id2 = id;
    
    f = f1;
    f1 = f2;
    f2 = f;
end

[bestNei, ~] = bestCijNei(id1, movieInfo, f2);

if id2 ~= bestNei
    return;
end

[bestNei, cost] = bestCijNei(id2, movieInfo, f1, true);

if id1 ~= bestNei
    return;
end

flag = true;


