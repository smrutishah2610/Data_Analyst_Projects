# ETL Pipeline Development

This project demonstrates the complete ETL (Extract, Transform, Load) process using SQL, showcasing data extraction, transformation, and loading into a data warehouse. The project is based on the **Wide World Importers** dataset.

## Table of Contents
- [Introduction](#introduction)
- [Project Structure](#project-structure)
- [ETL Process](#etl-process)
  - [Extract](#extract)
  - [Transform](#transform)
  - [Load](#load)
- [Prerequisites](#prerequisites)
- [Usage Instructions](#usage-instructions)
- [ETL Process Diagram](#etl-process-diagram)

## Introduction
The ETL process involves extracting data from the Wide World Importers operational database, transforming it to meet the business requirements, and loading it into a data warehouse. This project was developed as part of a university assignment to demonstrate understanding and application of ETL principles.

## Project Structure
```plaintext
ETL_Pipeline_Development/
├── ETL/                              # Main ETL SQL scripts
│   ├── assignment4_5_G16_ETL.sql    # Combined ETL scripts
├── WWI_DB/                           # Source database scripts
│   ├── Week 6 WWI_DB.sql            # Database creation script
│   ├── [Various INSERT Scripts].sql # Scripts for populating tables
├── WWI_DM/                           # Data warehouse scripts
│   ├── TransformScript.sql          # Transformation logic
│   ├── ExtractScript.sql            # Data extraction logic
│   ├── Load scripts for dimensions  # Loading data warehouse tables
│   ├── verify.sql                   # Validation queries
├── ETL Process Diagram.jpg           # Visual representation of the ETL flow
```

## ETL Process
### Extract
- The extraction phase retrieves data from the Wide World Importers database using SQL scripts provided in the `WWI_DB` folder.
- Scripts include:
  - Customer, Supplier, and Product tables
  - Orders and OrderLines

### Transform
- Data is cleaned, normalized, and transformed in this phase.
- Key transformation logic is in `TransformScript.sql` in the `WWI_DM` folder.
- Steps include:
  - Removing duplicates
  - Data type adjustments
  - Calculating derived metrics

### Load
- Transformed data is loaded into the data warehouse.
- Dimension and fact tables include:
  - Customers
  - Products
  - Orders
  - Locations

### ETL Sequence
Follow this sequence for running the ETL process:
1. Execute extraction scripts.
2. Run transformation scripts.
3. Load the transformed data into the data warehouse.

## Prerequisites
- SQL Server or a compatible database platform.
- Database setup using the provided scripts in the `WWI_DB` folder.
- SQL execution tool (e.g., SQL Server Management Studio).

## Usage Instructions
1. Set up the source database using `Week 6 WWI_DB.sql`.
2. Populate the database using the `INSERT` scripts from the `WWI_DB` folder.
3. Execute the `ExtractScript.sql` to extract data.
4. Run `TransformScript.sql` for data transformation.
5. Load the data warehouse tables using the scripts in the `WWI_DM` folder.
6. Validate the process using `verify.sql`.

## ETL Process Diagram
![ETL Process Diagram](/ETL_Pipeline_Development/ETL_Process_Diagram.jpg)
