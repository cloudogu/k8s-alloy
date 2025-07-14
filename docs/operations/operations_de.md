# k8s-alloy betreiben

## Installation

`k8s-alloy` kann als Komponente über den Komponenten-Operator des CES installiert werden.
Dazu muss eine entsprechende Custom-Resource (CR) für die Komponente erstellt werden.

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
```

Die neue yaml-Datei kann anschließend im Kubernetes-Cluster erstellt werden:

```shell
kubectl apply -f k8s-alloy.yaml --namespace ecosystem
```

Der Komponenten-Operator erstellt nun die `k8s-alloy`-Komponente im `ecosystem`-Namespace.

## Upgrade

Zum Upgrade muss die gewünschte Version in der Custom-Resource angegeben werden.
Dazu wird die erstellte CR yaml-Datei editiert und die gewünschte Version eingetragen.
Anschließend die editierte yaml Datei erneut auf den Cluster anwenden:

```shell
kubectl apply -f k8s-alloy.yaml --namespace ecosystem
```

## Konfiguration

Die Komponente kann über das Feld `spec.valuesYamlOverwrite` angepasst werden.
Konfigurationsmöglichkeiten entsprechen denen von [alloy](https://grafana.com/docs/alloy/latest/configure/kubernetes/).
Die Konfiguration für das Alloy Helm-Chart muss in der `values.yaml` unter dem Key `alloy` abgelegt werden.

**Beispiel:**

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

### Zusätzliche Konfiguration

Neben der oben beschriebenen Standard-Konfiguration von Alloy, verfügt die `k8s-alloy`-Komponente über zusätzliche
Konfiguration:

| Parameter               | Beschreibung                                                                         | Default-Wert |
|-------------------------|--------------------------------------------------------------------------------------|--------------|
| logLevel                | Konfiguriert das LogLevel in der Alloy ConfigMap                                     | `info`       |
| networkPolicies.enabled | Gibt an, ob eine NetworkPolicy für die Verbindung zu `k8s-loki` erstellt werden soll | `true`       |
