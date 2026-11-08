# Course Title: Google Spanner: Hands-On (2 days)

## Course Description

Traditional relational databases struggle to scale horizontally across regions while maintaining strong consistency and high availability. Conversely, distributed NoSQL databases often abandon relational schemas, strict ACID transactions, and standard SQL to achieve global scale.

This course teaches Google Cloud Spanner from foundational architecture through schema design, application programming, administration, and data migration. Through hands-on labs in Google Cloud, students provision instances, design interleaved schemas, execute transactions, build Python applications, tune performance, and migrate relational workloads to Spanner.

## Learning Objectives

- Design, administer, program, and migrate databases on Google Cloud Spanner
- Evaluate Spanner architecture and provision regional or multi-region database instances
- Design schemas that leverage table interleaving and prevent key hotspotting
- Query and manipulate data using SQL, mutations, and transaction modes
- Develop robust Python applications using the Cloud Spanner client library
- Monitor performance, configure autoscaling, and manage backup and recovery
- Assess, convert schemas, and migrate relational databases to Cloud Spanner

## Who Should Attend

Database administrators, software developers, data engineers, and cloud architects who want to build, administer, and migrate relational databases on Google Cloud Spanner.

## Prerequisites

- Experience working with relational databases and SQL
- Basic familiarity with Python programming
- Familiarity with Google Cloud Console navigation and concepts

## Hands-On Activities

- Lab: Creating and Configuring a Spanner Instance and Database
- Lab: Designing and Implementing an Interleaved Spanner Schema
- Lab: Querying, Mutating, and Tuning SQL Queries
- Lab: Building a Python Application with the Cloud Spanner API
- Lab: Monitoring, Scaling, and Backing Up a Spanner Database
- Lab: Migrating a Relational Database to Cloud Spanner

## Course Outline

**Module 1: Introduction to Google Cloud Spanner and Architecture**

- Cloud Spanner Overview and Core Concepts
- Spanner Architecture: TrueTime, Paxos, and Distributed Storage
- Comparing Spanner with Traditional RDBMS and NoSQL
- Regional and Multi-Region Deployment Options
- Instance Topologies, Nodes, and Processing Units
- Lab: Creating and Configuring a Spanner Instance and Database

**Module 2: Schema Design and Data Modeling**

- Data Types and Schemas in GoogleSQL and PostgreSQL Dialects
- Primary Keys and Avoiding Hotspots
- Table Interleaving and Parent-Child Relationships
- Secondary Indexes and Stored Columns
- Generated Columns and Check Constraints
- Lab: Designing and Implementing an Interleaved Spanner Schema

**Module 3: Querying and Data Manipulation with SQL**

- Query Execution and SQL Dialects in Spanner
- Data Manipulation Language and Mutations
- Query Optimizer and Execution Plans
- Transactions and Concurrency Control
- Read-Write Transactions, Read-Only Transactions, and Snapshot Reads
- Lab: Querying, Mutating, and Tuning SQL Queries

**Module 4: Developing Applications with the Python Client API**

- Google Cloud Spanner Python SDK Setup and Authentication
- Database Sessions, Connection Pools, and Life Cycles
- Executing Read-Write Transactions in Python
- Performing Snapshot Reads and Batched Reads
- Handling Errors, Retries, and Transaction Aborts
- Lab: Building a Python Application with the Cloud Spanner API

**Module 5: Database Administration and Operations**

- Managing Compute Capacity with Nodes and Processing Units
- Configuring Cloud Spanner Autoscaling
- Monitoring Metrics, Key Visualizer, and Query Insights
- Identity and Access Management and Data Security
- Backups, Restores, and Point-in-Time Recovery
- Lab: Monitoring, Scaling, and Backing Up a Spanner Database

**Module 6: Migrating Databases to Cloud Spanner**

- Migration Strategy and Assessment
- Schema Translation and Dialect Mapping
- Using the Spanner Migration Tool
- Bulk Data Loading and Change Data Capture
- Production Cutover and Zero-Downtime Strategies
- Lab: Migrating a Relational Database to Cloud Spanner
