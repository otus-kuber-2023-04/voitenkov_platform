# Инфраструктурная платформа на основе Kubernetes

## Занятия

## 1. Инфраструктурная платформа для разработки и эксплуатации цифровых продуктов (27.04.2023)

## 2. Знакомство с Kubernetes, основные понятия и архитектура (05.05.2023)
### Задание: 
- Разберитесь почему все pod в namespace kube-system восстановились после удаления. Укажите причину в описании PR. Hint: core-dns и, например, kube-apiserver, имеют различия в механизме запуска и восстанавливаются по разным причинам. 
- ⭐ Выясните причину, по которой pod frontend находится в статусе **Error**

### Полезные ссылки

- [kubectl](https://kubernetes.io/ru/docs/tasks/tools/install-kubectl/) 
- [minikube](https://kubernetes.io/ru/docs/tasks/tools/install-minikube/)
- [StaticPods](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)
- [Pods Overview](https://kubernetes.io/docs/concepts/workloads/pods/pod-overview/)
- [Kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
- [Описание выполненного ДЗ](kubernetes-intro/README.md)
