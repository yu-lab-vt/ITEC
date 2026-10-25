function TrackingWithCorrections(q)
% Run ITEC tracking while preserving manually locked parent associations.
q.enable_locked_correction = true;
Tracking(q);
end