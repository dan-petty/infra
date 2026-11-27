# Proposal

## Why

Prometheus holds no container start series for a pod, so the start time of a runner Job cannot be measured (#174). The kube-state-metrics scrape tuning of the k8s-monitoring values template omits the container start gauge, so the alloy-metrics collector drops that series. The change adds the name to the tuning list. After a consumer pins the next release, Prometheus gets one series for each running or terminated container of a pod, with the container start time in Unix seconds as its value.

## What Changes

- Add the name kube_pod_container_state_started to the kube-state-metrics includeMetrics list of `helm/k8s-monitoring/values.yaml`, directly after the kube_pod_container_status_waiting entry, with the same indentation, and change no other line of the file.
- State in the plan and the manual check that this list tunes the scrape of the alloy-metrics collector, so the name reaches the rendered Alloy configuration of that collector and no argument of the kube-state-metrics Deployment.
- Prove the entry with the shared K8s validation of the repository, which lints and renders the values template through the test chart of the folder; a person runs it on a workstation, because helm, kustomize and kubeconform are no tools of the implementation runner.
- Leave the live proof of the series to a person, as a Pending-a-person line of the tasks: the series reaches a cluster only after an infra release that holds the change and after the consumer moves the pinned infra tag of its k8s-monitoring Application to that release.
- Carry a spec delta for the new capability k8s-monitoring-values, because a Helm values template is a config file that a consumer observes and no existing capability describes one.
- The change fits one pull request.

## Capabilities

### New Capabilities

- `k8s-monitoring-values`: The kube-state-metrics allowlist keeps the container start series

### Modified Capabilities

None.

## Impact

- Code: `helm/k8s-monitoring/values.yaml`

## Feasibility

- The probe answered, word for word: "The path `helm/k8s-monitoring/values.yaml` is a file of the staging commit." So the values template that the change edits exists at the staged commit.
- The probe answered, word for word: "The path `scripts/k8s-validate.sh` is a file of the staging commit." and "The path `AGENTS.md` is a file of the staging commit." and "The path `README.md` is a file of the staging commit." So the shared K8s check script and the documents that the plan cites exist at the staged commit.
- The probe answered, word for word: "The path `metricsTuning.includeMetrics` is no file of the staging commit. No commit in the history deleted or renamed it." and the same for `clusterMetrics.kube-state-metrics.metricsTuning.includeMetrics`, so both names are keys of the values file and no commit removed a path.
- The probe answered, word for word: "Not probed, the bound of 10 commands is reached: `.github/workflows/k8s-validate.yml`, `helm/k8s-monitoring/test-chart/Chart.yaml`, `telemetryServices.kube-state-metrics.deploy`, `and.proposal`, `kube_pod_container_state_started`, `includeMetrics`, `kube_pod_container_status_waiting`", so this run read those paths and names with the calls below.
- `read_file` of `helm/k8s-monitoring/values.yaml` lines 1 to 60 showed `helm/k8s-monitoring/values.yaml:13:clusterMetrics:`, `helm/k8s-monitoring/values.yaml:15:collector: alloy-metrics`, `helm/k8s-monitoring/values.yaml:32:kube-state-metrics:`, `helm/k8s-monitoring/values.yaml:33:discoveryType: service`, `helm/k8s-monitoring/values.yaml:35:includeMetrics:`, `helm/k8s-monitoring/values.yaml:54:- kube_pod_container_status_waiting` and `helm/k8s-monitoring/values.yaml:55:- kube_deployment_status_replicas_unavailable`, so the new name goes between line 54 and line 55 and the list holds 20 names before the change.
- `read_file` of `helm/k8s-monitoring/values.yaml` lines 163 to 190 showed `helm/k8s-monitoring/values.yaml:165:telemetryServices:`, `helm/k8s-monitoring/values.yaml:169:collectorsExtra:` and `helm/k8s-monitoring/values.yaml:171:metricLabelsAllowlist:`, so the settings of the kube-state-metrics Deployment live in a block of their own, apart from the block at line 32.
- `search_code` for `metricLabelsAllowlist` answered one hit at `helm/k8s-monitoring/values.yaml:171:metricLabelsAllowlist:` and `search_code` for `collectorsExtra` answered one hit at `helm/k8s-monitoring/values.yaml:169:collectorsExtra:`, so the Deployment side of the file holds no metric-name list and no metric allowlist flag.
- The review's finding is a real defect and the plan fixes it: the block of `helm/k8s-monitoring/values.yaml:13:clusterMetrics:` names `helm/k8s-monitoring/values.yaml:15:collector: alloy-metrics` and gives its kube-state-metrics entry `helm/k8s-monitoring/values.yaml:33:discoveryType: service`, so the includeMetrics list tunes the collector's scrape; the manual check now reads the name in the rendered Alloy configuration of the alloy-metrics collector and no longer in the arguments of the Deployment, which the render gives from the block of `helm/k8s-monitoring/values.yaml:165:telemetryServices:`.
- `search_code` for `kube_pod_container_state_started` answered "No match.", so no file of the staged commit holds the name and the change adds it.
- `search_code` for `k8s-monitoring/test-chart` answered `.github/workflows/ci.yml:199:helm/k8s-monitoring/test-chart`, so the K8s job of CI renders the values template through the test chart of the folder.
- `read_file` of `helm/k8s-monitoring/test-chart/Chart.yaml` showed `helm/k8s-monitoring/test-chart/Chart.yaml:2:name: test-chart`, `helm/k8s-monitoring/test-chart/Chart.yaml:5:- name: k8s-monitoring` and `helm/k8s-monitoring/test-chart/Chart.yaml:7:repository: https://grafana.github.io/helm-charts`, so the test chart has one dependency and the render gives the values template under the name k8s-monitoring.
- `list_files` of `helm/k8s-monitoring/test-chart` returned `.helmignore`, `Chart.lock`, `Chart.yaml`, `ci`, `templates` and `values.yaml` and no `tests` folder, so the test chart holds no unit test case and the change adds none.
- `read_file` of `helm/README.md` lines 1 to 40 showed `helm/README.md:15:The K8s job of CI lints, renders and checks the test chart` and `helm/README.md:20:The unit tests of the template are in` and the row of the k8s-monitoring template, so the shared check renders the template and the unit tests of a test chart live in its tests folder.
- `read_file` of `README.md` lines 280 to 300 showed `README.md:288:| K8s |`, so the K8s check of the repository is the shared script and not a command of the devops gate.
- `read_spec` of `ci-check-names` and of `pr-title-scopes` gave purposes about the check names of `ci.yml` and the scopes of the pull request title check, and the capabilities of the inputs are only `ci-check-names`, `pr-title-scopes` and `renovate-titles`, so no capability of the project describes a Helm values template and the delta adds the capability k8s-monitoring-values.
- `list_files` of the repository root returned `helm`, `k8s`, `scripts`, `tests`, `openspec` and no `src` folder, so this repository holds no Python package under `src/` and no behavior group is possible here.
- Precondition of the manual check: a checkout of the repository and a network, because the render runs `helm dependency build` on the chart of `helm/k8s-monitoring/test-chart/Chart.yaml:7:repository: https://grafana.github.io/helm-charts`. The plan calls no function that needs a checkout, a client or a network.
- First check against the real system: `KUSTOMIZE_ROOTS= HELM_CHARTS=helm/k8s-monitoring/test-chart PROMTOOL_RULES= TRIVY_IGNORE_FILE=helm/.trivyignore.yaml mise exec -- scripts/k8s-validate.sh all` from the repository root must exit with status 0 and print the line `helm lint and helm template helm/k8s-monitoring/test-chart`.
- Second check against the real system: the same command with the variable RENDERED set to an empty folder outside the repository writes the rendered objects there, and `grep -rl kube_pod_container_state_started` of that folder must name the one file `1-helm-k8s-monitoring/default/ConfigMap-k8s-monitoring-alloy-metrics.yaml`, the Alloy configuration of the alloy-metrics collector, and no Deployment file.
- A run of both checks on 2026-11-27 with the tools of `mise.toml` proved that only the second check can fail: on the staged commit the command exited with status 0 and printed `helm lint and helm template helm/k8s-monitoring/test-chart helm/k8s-monitoring/test-chart/ci/test-values.yaml`, and the grep found no file; with the new entry the command again exited with status 0, and the grep named only that ConfigMap file.
- A `helm template` of k8s-monitoring 4.6.2 with the values template, before and after the new entry, differed in one line: the regex of the keep rule of `prometheus.relabel "kube_state_metrics"` in the ConfigMap `k8s-monitoring-alloy-metrics`. The kube-state-metrics Deployment of the render has no `--metric-allowlist` and no `--metric-denylist` argument, and its `--resources` argument holds `pods`, so kube-state-metrics serves the gauge and the keep rule is the only filter.
- The default allow list of the chart, `charts/feature-cluster-metrics/default-allow-lists/kube-state-metrics.yaml` of k8s-monitoring 4.6.2, holds no `kube_pod_container_state_started`, so the series needs the includeMetrics entry.
- kube-state-metrics v2.20.0, the image of the render, defines the STABLE gauge in `internal/store/pod.go` lines 304 to 335: one series for each running or terminated container of `status.containerStatuses`, with the labels `namespace`, `pod`, `uid` and `container` and the start time in Unix seconds as its value. A restart of a container in the same pod changes the value of its series and adds no series.
- The live Prometheus of a consumer cluster on 2026-11-27 returned "No results." for `count(kube_pod_container_state_started)` and 305 for `count(kube_pod_container_status_waiting)`, all with `job="integrations/kubernetes/kube-state-metrics"`, so the scrape of kube-state-metrics works and the keep rule drops the gauge today.
- Runner capability: `helm`, `kustomize` and `kubeconform` are NOT_IN_RUNNER. For `helm` and `kustomize` the reason is "No check, hook, test or job of the gate runs it"; for `kubeconform` it is "A scanner of `devops scan report`". `mise` and `yq` are no tools of the runner image, so the K8s validation runs on a workstation with the pinned tools; the change introduces no verify command, so the implementation step starts no program of this check.
- Failure classes of the K8s check: a lint error of the test chart, a render error, a schema error of kubeconform, a kube-linter finding, a trivy finding of HIGH or CRITICAL severity, a missing tool, and a chart repository that the network cannot reach each stop the command with a non-zero status.
- The change fits one pull request: one values line, one manual check on a workstation and one spec delta.

## Existing Tool Considered

kubernetes/kube-state-metrics (Apache-2.0, maintained, last activity 2026-11-25) is the exporter that the k8s-monitoring chart already deploys; the change accepts its container start gauge through the includeMetrics tuning of the values template and builds no code, so it adds no build, maintenance or repair cost.

## Dependencies

None.
