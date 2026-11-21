# Helm values templates

Each folder `helm/<chart>/` holds the values template `values.yaml` of one upstream chart: the
settings that are true for each cluster, such as security contexts, probes and alert rules. A
values template holds no value of one environment. The consumer gives the template to the upstream
chart, for example as a value file of an Argo CD Application, and adds its own values.

Each values template has a test chart that pins the upstream chart at one exact version, as a
dependency in its `Chart.yaml`, and renders it with the template. The K8s job of CI lints, renders
and checks the test chart (README.md, "Checks"). `helm lint --strict` needs a `values.yaml` and a
`templates/` folder in the test chart.

This folder has no values template yet. dan-petty/infra#17, #18 and #19 add the first templates
and their test charts.
