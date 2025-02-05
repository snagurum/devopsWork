# postgres-backup

K8S cronjob for backing up postgres db running as a pod.

Script backsup 3 databases running in dev environment. 

1. Keycloak DB
2. SonarQube DB
3. User-Mgmt DB

## Required Paramateres for the db backup script.

1. S3_BUCKET, S3-Bucket name
2. S3_PREFIX, S3-Prefix foldername[environment]
3. POSTGRES_HOST, DB hostname
4. POSTGRES_USER, DB username
5. POSTGRES_PASSWORD, DB password
6. POSTGRES_DATABASE, DB database name
7. S3_ACCESS_KEY_ID, S3 access key id
8. S3_SECRET_ACCESS_KEY, S3 secret access key
9. RETENTION_DAYS[Optional] default 21 days
10. POSTGRES_PORT[Optional] default 5432
11. ENCRYPTION_PASSWORD[Optional] provide password to enable encryption using AES 256 CBC.

## Installation steps.

Use Helm dysnix raw module. resource information is stored in cronjob.yml for dev environment.

 "helm install db-backup-cronjobs dysnix/raw -f cronjob.yaml --version 0.3.1 -n ahdev"

## S3-Bucket backup structure

 \+ dev   
&nbsp; &nbsp; &nbsp;     |  
&nbsp; &nbsp; &nbsp;    + keycloak   
&nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp;     |  
&nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp;         + 20250131   
&nbsp; &nbsp; &nbsp;    + sonarqube   
&nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp;     |  
&nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp;         + 202501031  
&nbsp; &nbsp; &nbsp;    + usermgmt   
&nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp;     |  
&nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp;         + 202501031  


