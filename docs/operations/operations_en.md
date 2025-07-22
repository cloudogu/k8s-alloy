# operate k8s-alloy

## Installation

`k8s-alloy` can be installed as a component via the CES component operator.
To do this, a corresponding custom resource (CR) must be created for the component.

```yaml
apiVersion: k8s.cloudogu.com/v1
kind: Component
metadata:
  name: k8s-alloy
  labels:
    app: ces
spec:
  name: k8s-alloy
  namespace: k8s
  version: 1.1.2-0
````

The new yaml file can then be created in the Kubernetes cluster:

```shell
kubectl apply -f k8s-alloy.yaml --namespace ecosystem
```

The component operator now creates the `k8s-alloy` component in the `ecosystem` namespace.

## Upgrade

To upgrade, the desired version must be specified in the custom resource.
To do this, the CR yaml file created is edited and the desired version is entered.
Then reapply the edited yaml file to the cluster:

```shell
kubectl apply -f k8s-alloy.yaml --namespace ecosystem
```

## Configuration

The component can be customised via the `spec.valuesYamlOverwrite` field.
Configuration options correspond to those of [alloy](https://grafana.com/docs/alloy/latest/configure/kubernetes/).
The configuration for the Alloy Helm chart must be stored in `values.yaml` under the key `alloy`.

**Example:**

```yaml
apiVersion: k8s.cloudogu.com/v1
kind: Component
metadata:
  name: k8s-alloy
  labels:
    app: ces
spec:
  name: k8s-alloy
  namespace: k8s
  version: 1.1.2.0
  valuesYamlOverwrite: |
    alloy:
      service:
        enabled: true
```

### Additional configuration

In addition to the standard Alloy configuration described above, the `k8s-alloy` component has additional configuration:

| Parameter               | Description                                                                          | Default value |
|-------------------------|--------------------------------------------------------------------------------------|---------------|
| logLevel                | Configures the LogLevel in the Alloy ConfigMap                                       | `info`        |
| networkPolicies.enabled | Specifies whether a NetworkPolicy should be created for the connection to `k8s-loki` | `true`        |
