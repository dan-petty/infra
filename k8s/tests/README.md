# Test overlays

Each folder `k8s/tests/<template>/` is the test overlay of one base or component of `k8s/`. It
builds the template with the values of a test: `example.com` for `<domain>`, and RFC 5737 addresses
(192.0.2.0/24, 198.51.100.0/24 and 203.0.113.0/24). No consumer uses a test overlay.

The K8s job of CI gives each test overlay to the reusable workflow `k8s-validate.yml` as a
Kustomize root. To add a test overlay to CI, add its folder to the input `kustomize-roots` of the
job `k8s` in `.github/workflows/ci.yml`.
