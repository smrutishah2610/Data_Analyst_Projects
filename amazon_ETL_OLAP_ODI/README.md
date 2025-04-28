# Amazon Sales Analysis

## Overview
This project explores **ETL (Extract, Transform, Load) processes**, **Online Analytical Processing (OLAP)**, and **Oracle Data Integrator (ODI)**. We built a robust data warehouse to analyze Amazon sales data using **Oracle Analytics Workspace Manager** for OLAP cube creation and ODI for automating ETL workflows.

Despite having no prior experience with these tools, our team successfully delivered the project through **self-learning**, **team collaboration**, and **effective time management**.

## Features
- **ETL Process**:
  - Designed and implemented a pipeline to extract, transform, and load Amazon sales data.
  - Managed datasets like users, orders, items, vendors, and regions.
- **OLAP Cube with Oracle Analytics Workspace Manager**:
  - Created a multidimensional cube for efficient data analysis.
  - Enabled insights into sales trends, vendor performance, and regional analysis.
- **ODI Automation**:
  - Configured Oracle Data Integrator for automating ETL workflows, reducing errors and manual effort.
- **Data Modeling**:
  - Designed entity-relationship diagrams, star schemas, and relational models for seamless data organization.

## File Structure
```plaintext
📂 Amazon_ETL_OLAP_ODI
├── 📂 Data (CSV files for input data)
│   ├── Users.csv
│   ├── Items.csv
│   ├── Orderdata.csv
│   ├── ... (other related files)
├── 📂 Diagrams
│   ├── ETL Process.png
│   ├── ERD.png
│   ├── STAR DATA MODEL.png
│   ├── ... (other visuals)
├── 📂 Documentation
│   ├── OLAP.docx
│   ├── ODI.docx
├── 📂 Scripts
│   ├── ETL_All_Script.sql
│   ├── STAR Script.sql
│   ├── ERD Relational Model.sql
├── Amazon_Sales_PreRecording.mp4 (Project explanation video)
├── Amazon_ppt.pptx (Project presentation)
```

## Steps to Run the Project
### Prerequisites
1. **Software**:
   - Oracle Data Integrator (ODI)
   - Oracle Analytics Workspace Manager for OLAP
   - Oracle Database
   - Diagramming tools (optional, e.g., Diagrams.net)

2. **Files**:
   - Download all project files from this repository.

### Setup Instructions
1. **Database Configuration**:
   - Create a database in your Oracle instance.
   - Execute the scripts from the `Scripts` folder to create tables and populate data.

2. **ETL Process**:
   - Use `ETL_All_Script.sql` to perform the ETL process manually or automate it with ODI.

3. **OLAP Cube Creation**:
   - Open Oracle Analytics Workspace Manager.
   - Create a new workspace for your data warehouse.
   - Design the OLAP cube using the `STAR DATA MODEL.png` as a reference.
   - Load data into the cube and test with sample queries.

4. **ODI Integration**:
   - Configure ODI to connect to your Oracle Database.
   - Automate ETL workflows using graphical transformations in ODI.

5. **Run the Project**:
   - Verify database connections and OLAP cube.
   - Analyze data using the OLAP cube and generate insights.

### Outputs
- Sales insights, vendor performance, and trend analysis using the OLAP cube.
- Automated ETL processes with ODI.
- Visualizations showcasing the data model and sales performance.

## Recordings
We have included a detailed video explanation (`Amazon_Sales_PreRecording.mp4`) where we explain the entire project step by step. The recording covers:
- The overall project flow.
- Hands-on demonstrations of **Oracle Data Integrator (ODI)**.
- Creating and using OLAP cubes with **Oracle Analytics Workspace Manager**.
