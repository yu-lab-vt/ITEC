# ITEC: Manual Correction and Iterative Re-tracking

This experimental extension lets users correct selected parent associations and re-run ITEC with those associations constrained. The remaining associations are re-optimized during iterative tracking, allowing a manual correction to influence related matches. Improvement of every related mismatch is not guaranteed.

For installation, datasets, standard parameters, and the original workflow, see the [main branch](https://github.com/yu-lab-vt/ITEC/tree/main).

## What this extension adds

- Import selected parent edits from a CSV patch.
- Fix a detection's incoming association to a specified parent, or require it to have no parent.
- Re-run the tracking and error-correction iterations while protecting detections involved in the edits.
- Optionally start tracking from a supplied segmentation label-map sequence.

Corrections are applied through a MATLAB script. This workflow runs again after edits are supplied; it does not provide a live correction GUI or incremental real-time updates.

## Prepare a correction patch

Create a CSV containing only the associations you intend to constrain:

```csv
ID,parents,locked
103,42,true
104,,true
```

| Column | Meaning |
| --- | --- |
| `ID` | Detection ID in the segmentation used to initialize this re-run. |
| `parents` | Parent detection ID. An empty value or `NaN` requires the detection to have no parent. |
| `locked` | `true` or `1` applies the constraint. Rows marked `false` or `0` are ignored. |

In this illustrative patch, detection `103` must have parent `42`, and detection `104` must have no parent. Replace these IDs with IDs from your own data. Each constrained detection may occur only once, and each parent may be assigned to only one constrained child.

**Detection IDs must match the segmentation used for this re-run.** Tracking can add, remove, or renumber detections. IDs in a previous final `tracking_result.csv` may therefore differ from IDs reconstructed from the original segmentation cache. Verify the correspondence before applying a patch; the importer checks ranges, time order, and candidate membership, but does not establish correspondence by coordinates.

Use a patch containing only deliberate edits. The exported `locked` column marks protected detections, including parent endpoints of edited connections; it should not be treated as a list of incoming associations to constrain again automatically.

## Run constrained tracking

Start in the repository's `src` directory. Use a parameter file from the original run so that the raw data, frame range, preprocessing, and existing segmentation cache are available.

```matlab
addpath(genpath(pwd));
[~, ~, q] = set_paras('params.csv');

q.correction_csv_path = 'E:/experiment/manual_edits.csv';

% Keep q.tmp_path pointing to the existing preprocessing cache.
% Write the new tracking outputs to a separate directory.
q.result_path = 'E:/experiment/retracked_result';

TrackingWithCorrections(q);
```

`TrackingWithCorrections` enables correction mode and calls the tracking pipeline. The standard `demo.m` continues to use the ordinary tracking entry point. There is no need to call `InstanceSegmentation` again when reusing compatible cached inputs.

### Reuse a final segmentation

If the patch refers to a previous final tracking result, its corresponding final segmentation is a possible starting point, provided its label numbering matches the CSV IDs. The original tracking output stores the label maps as `out_refine_res`, whereas the correction input requires a variable named `refine_res`:

```matlab
S = load('E:/experiment/original_result/refine_res.mat', 'out_refine_res');
refine_res = S.out_refine_res;
save('E:/experiment/corrected_segmentation.mat', 'refine_res', '-v7.3');

% Set this before calling TrackingWithCorrections(q).
q.corrected_segmentation_path = 'E:/experiment/corrected_segmentation.mat';
```

The supplied label maps must have the expected frame count, spatial dimensions, and preprocessing coordinate system. This option replaces only the segmentation label maps; threshold and curvature data still come from the existing cache. Compatibility with those cached inputs must be checked, particularly after adding, deleting, or relabeling regions.

## How corrections affect the iterations

The importer runs after initial candidate transition costs have been computed. For a constrained child, competing incoming links are excluded and the selected link receives a strongly favorable cost. The tracker checks the resulting parent associations and raises an error if a constraint is violated.

The subsequent segmentation-correction and missing-cell iterations continue. Detections involved in manual edits are protected from selected removal, split/merge, and division operations. Other associations remain available for re-optimization. The usual tracking outputs are written to `q.result_path`.

## Current limits and validation

- Only ordinary one-to-one parent associations are supported. Manually constraining a mother to two daughters is not supported.
- A requested link must already be an eligible candidate. A parent must precede its child in time. Importing a CSV does not create missing detections or arbitrary new candidate links.
- Use adjacent-frame links for this prototype. The split/merge stage removes jump links, so a lock across a frame gap can fail later even if it passes the initial import checks.
- When locks are active, broken-track repair and the final broken-track merge are skipped. Division additions involving protected detections are also skipped. These safeguards limit which related errors can be corrected automatically.
- The optional segmentation input is not a complete saved-state resume mechanism. Check detection numbering and cached segmentation-dependent data before reusing a previous result.

A minimal smoke check passed in MATLAB R2024b for CSV constraint import and the bundled CINDA solver. In a synthetic assignment example, favoring one corrected connection caused another connection to be reassigned. This check does not establish end-to-end correctness, correction accuracy on real data, or real-time performance.
