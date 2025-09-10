function movieInfo_noJump = build_movieInfo_noJump(movieInfo)
%% build no jump movieInfo
movieInfo_noJump = movieInfo;
for i=1:numel(movieInfo_noJump.nei)
    if ~isempty(movieInfo_noJump.nei)
        validNeiIdx = (movieInfo_noJump.frames(movieInfo_noJump.nei{i}) == ...
            movieInfo_noJump.frames(i)+1) & ~isinf(movieInfo_noJump.Cij{i});
        movieInfo_noJump.nei{i} = movieInfo_noJump.nei{i}(validNeiIdx);
        movieInfo_noJump.Cij{i} = movieInfo_noJump.Cij{i}(validNeiIdx);
        movieInfo_noJump.ovSize{i} = movieInfo_noJump.ovSize{i}(validNeiIdx);
        movieInfo_noJump.CDist{i} = movieInfo_noJump.CDist{i}(validNeiIdx);
        movieInfo_noJump.CDist_i2j{i} = movieInfo_noJump.CDist_i2j{i}(validNeiIdx,:);
    end
    if ~isempty(movieInfo_noJump.preNei)
        validPreNeiIdx = movieInfo_noJump.frames(movieInfo_noJump.preNei{i}) == ...
            movieInfo_noJump.frames(i)-1 & ~isinf(movieInfo_noJump.Cji{i});
        movieInfo_noJump.preNei{i} = movieInfo_noJump.preNei{i}(validPreNeiIdx);
        movieInfo_noJump.Cji{i} = movieInfo_noJump.Cji{i}(validPreNeiIdx);
        movieInfo_noJump.preOvSize{i} = movieInfo_noJump.preOvSize{i}(validPreNeiIdx);
        movieInfo_noJump.CDist_j2i{i} = movieInfo_noJump.CDist_j2i{i}(validPreNeiIdx);
    end
end
end