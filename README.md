# nifi-tls-csd
Cloudera Service Descriptor for NiFi TLS Infrastructure

[![Build Status](https://travis-ci.org/nomr/nifi-tls-csd.svg?branch=master)](https://travis-ci.org/nomr/nifi-tls-csd)


## Storage Provider

### PostgreSQL
```sql
CREATE USER "hwx-registry" WITH LOGIN ENCRYPTED PASSWORD 'password';
CREATE DATABASE "hwx-registry" OWNER "hwx-registry";
```
