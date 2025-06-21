### To run run the infrastracture:
~~~
terraform apply
~~~

### To configure Kubectl:
~~~
aws eks update-kubeconfig --region us-east-1 --name my-eks-cluster
~~~

### To see nodes from the console as root:
1. edit aws-auth
~~~
kubectl edit configmap aws-auth -n kube-system
~~~
2. paste the following
~~~
apiVersion: v1
data:
  mapRoles: |
    - groups:
      - system:bootstrappers
      - system:nodes
      rolearn: arn:aws:iam::801891517247:role/default-eks-node-group-2025062109272547520000000a
      username: system:node:{{EC2PrivateDNSName}}
  mapUsers: |
    - userarn: arn:aws:iam::801891517247:root
      username: root
      groups:
        - system:masters
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
~~~

### Running a debug postgres pod:
1. run the pod
~~~
kubectl apply -f psql-debug.yaml
~~~
2. Enter the pod
~~~
kubectl exec -it psql-debug -- bash
~~~
3. Connect to DB
~~~
psql -h <your-rds-endpoint> -U <your-db-user> -d <your-db-name>
~~~

### Generate the self signed certificate
Run the following in terminal:
~~~
openssl req -x509 -newkey rsa:4096 -nodes \
  -keyout tls.key \
  -out tls.crt \
  -days 365 \
  -subj "/CN=localhost"
~~~

#### Add the generated certificate to kubernetes as a secret
~~~
kubectl create secret tls nginx-tls \
  --cert=tls.crt \
  --key=tls.key
~~~