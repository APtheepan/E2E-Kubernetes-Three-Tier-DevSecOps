#!/bin/bash
echo "Please enter your clustername:"
read clustername

echo "Please enter your your_account_id:"
read your_account_id

aws eks update-kubeconfig --region us-east-1 --name $clustername

aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json

#Create the IAM role for the AWS Load Balancer Controller
eksctl create iamserviceaccount --cluster=$clustername --namespace=kube-system --name=aws-load-balancer-controller --role-name AmazonEKSLoadBalancerControllerRole --attach-policy-arn=arn:aws:iam::$your_account_id:policy/AWSLoadBalancerControllerIAMPolicy --approve --region=us-east-1

#Install helm to install the aws-load-balancer-controller
sudo snap install helm --classic
helm repo add eks https://aws.github.io/eks-charts
helm repo update eks
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=my-cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller

#Create a namespace for argocd and install argocd
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.4.7/manifests/install.yaml
#Change the service type to LoadBalancer
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
