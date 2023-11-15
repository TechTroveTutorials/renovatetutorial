{{/*
Demo component Deployment template
*/}}
{{- define "monitoring.deployment" }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "monitoring.name" . }}-{{ .name }}
  labels:
    {{- include "monitoring.labels" . | nindent 4 }}
spec:
  replicas: {{ .replicas | default .defaultValues.replicas }}
  selector:
    matchLabels:
      {{- include "monitoring.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      labels:
        {{- include "monitoring.selectorLabels" . | nindent 8 }}
        {{- include "monitoring.workloadLabels" . | nindent 8 }}
      {{- if .podAnnotations }}
      annotations:
        {{- toYaml .podAnnotations | nindent 8 }}
      {{- end }}
    spec:
      {{- if or .defaultValues.image.pullSecrets ((.imageOverride).pullSecrets) }}
      imagePullSecrets:
        {{- ((.imageOverride).pullSecrets) | default .defaultValues.image.pullSecrets | toYaml | nindent 8}}
      {{- end }}
      serviceAccountName: {{ include "monitoring.serviceAccountName" .}}
      {{- $schedulingRules := .schedulingRules | default dict }}
      {{- if or .defaultValues.schedulingRules.nodeSelector $schedulingRules.nodeSelector}}
      nodeSelector:
        {{- $schedulingRules.nodeSelector | default .defaultValues.schedulingRules.nodeSelector | toYaml | nindent 8 }}
      {{- end }}
      {{- if or .defaultValues.schedulingRules.affinity $schedulingRules.affinity}}
      affinity:
        {{- $schedulingRules.affinity | default .defaultValues.schedulingRules.affinity | toYaml | nindent 8 }}
      {{- end }}
      {{- if or .defaultValues.schedulingRules.tolerations $schedulingRules.tolerations}}
      tolerations:
        {{- $schedulingRules.tolerations | default .defaultValues.schedulingRules.tolerations | toYaml | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ .name }}
          image: '{{ ((.imageOverride).repository) | default .defaultValues.image.repository }}:{{ ((.imageOverride).tag) | default (printf "%s-%s" (default .Chart.AppVersion .defaultValues.image.tag) (replace "-" "" .name)) }}'
          imagePullPolicy: {{ ((.imageOverride).pullPolicy) | default .defaultValues.image.pullPolicy }}
          {{- if .command }}
          command:
            {{- .command | toYaml | nindent 10 -}}
          {{- end }}
          {{- if or .ports .service}}
          ports:
            {{- include "monitoring.pod.ports" . | nindent 10 }}
          {{- end }}
          env:
            {{- include "monitoring.pod.env" . | nindent 10 }}
          resources:
            {{- .resources | toYaml | nindent 12 }}
          {{- if or .defaultValues.securityContext .securityContext }}
          securityContext:
            {{- .securityContext | default .defaultValues.securityContext | toYaml | nindent 12 }}
          {{- end}}
          {{- if .livenessProbe }}
          livenessProbe:
            {{- .livenessProbe | toYaml | nindent 12 }}
          {{- end }}
      {{- if .configuration }}
          volumeMounts:
          - name: config
            mountPath: /etc/config
      volumes:
        - name: config
          configMap:
            name: {{ include "monitoring.name" . }}-{{ .name }}-config
      {{- end }}
      {{- if .initContainers }}
      initContainers:
        {{- tpl (toYaml .initContainers) . | nindent 8 }}
      {{- end}}
{{- end }}

{{/*
Demo component Service template
*/}}
{{- define "monitoring.service" }}
{{- if or .ports .service}}
{{- $service := .service | default dict }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ include "monitoring.name" . }}-{{ .name }}
  labels:
    {{- include "monitoring.labels" . | nindent 4 }}
  {{- with $service.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  type: {{ $service.type | default "ClusterIP" }}
  ports:
    {{- if .ports }}
    {{- range $port := .ports }}
    - port: {{ $port.value }}
      name: {{ $port.name}}
      targetPort: {{ $port.value }}
    {{- end }}
    {{- end }}

    {{- if $service.port }}
    - port: {{ $service.port}}
      name: tcp-service
      targetPort: {{ $service.port }}
      {{- if $service.nodePort }}
      nodePort: {{ $service.nodePort }}
      {{- end }}
    {{- end }}
  selector:
    {{- include "monitoring.selectorLabels" . | nindent 4 }}
{{- end}}
{{- end}}

{{/*
Demo component ConfigMap template
*/}}
{{- define "monitoring.configmap" }}
{{- if .configuration}}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "monitoring.name" . }}-{{ .name }}-config
  labels:
    service: {{ include "monitoring.name" . }}-{{ .name }}
    app: {{ include "monitoring.name" . }}-{{ .name }}
    component: {{ include "monitoring.name" . }}-{{ .name }}-config
data:
  {{- .configuration | toYaml | nindent 2}}
{{- end}}
{{- end}}

{{/*
Demo component Ingress template
*/}}
{{- define "monitoring.ingress" }}
{{- $hasIngress := false}}
{{- if .ingress }}
{{- if .ingress.enabled }}
{{- $hasIngress = true }}
{{- end }}
{{- end }}
{{- $hasServicePorts := false}}
{{- if .service }}
{{- if .service.port }}
{{- $hasServicePorts = true }}
{{- end }}
{{- end }}
{{- if and $hasIngress (or .ports $hasServicePorts) }}
{{- $ingresses := list .ingress }}
{{- if .ingress.additionalIngresses }}
{{-   $ingresses := concat $ingresses .ingress.additionalIngresses -}}
{{- end }}
{{- range $ingresses }}
---
apiVersion: "networking.k8s.io/v1"
kind: Ingress
metadata:
  {{- if .name }}
  name: {{include "monitoring.name" $ }}-{{ $.name }}-{{ .name }}
  {{- else }}
  name: {{include "monitoring.name" $ }}-{{ $.name }}
  {{- end }}
  labels:
    {{- include "monitoring.labels" $ | nindent 4 }}
  {{- if .annotations }}
  annotations:
    {{ toYaml .annotations | nindent 4 }}
  {{- end }}
spec:
  {{- if .ingressClassName }}
  ingressClassName: {{ .ingressClassName }}
  {{- end -}}
  {{- if .tls }}
  tls:
    {{- range .tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      {{- with .secretName }}
      secretName: {{ . }}
      {{- end }}
    {{- end }}
  {{- end }}
  rules:
    {{- range .hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ .path }}
            pathType: {{ .pathType }}
            backend:
              service:
                name: {{ include "monitoring.name" $ }}-{{ $.name }}
                port:
                  number: {{ .port }}
          {{- end }}
    {{- end }}
{{- end}}
{{- end}}
{{- end}}