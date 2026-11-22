import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame

def sparkSqlQuery(glueContext, query, mapping, transformation_ctx) -> DynamicFrame:
    for alias, frame in mapping.items():
        frame.toDF().createOrReplaceTempView(alias)
    result = spark.sql(query)
    return DynamicFrame.fromDF(result, glueContext, transformation_ctx)
args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Script generated for node Amazon S3
AmazonS3_node1795360315599 = glueContext.create_dynamic_frame.from_catalog(database="superstore_catalog", table_name="bruto", transformation_ctx="AmazonS3_node1795360315599")

# Script generated for node Change Schema
ChangeSchema_node1795360546775 = ApplyMapping.apply(frame=AmazonS3_node1795360315599, mappings=[("row id", "long", "row_id", "long"), ("order id", "string", "order_id", "string"), ("order date", "string", "order_date", "string"), ("ship date", "string", "ship_date", "string"), ("ship mode", "string", "ship_mode", "string"), ("customer id", "string", "customer_id", "string"), ("customer name", "string", "customer_name", "string"), ("segment", "string", "segment", "string"), ("country", "string", "country", "string"), ("city", "string", "city", "string"), ("state", "string", "state", "string"), ("postal code", "long", "postal_code", "long"), ("region", "string", "region", "string"), ("product id", "string", "product_id", "string"), ("category", "string", "category", "string"), ("sub-category", "string", "sub_category", "string"), ("product name", "string", "product_name", "string"), ("sales", "double", "sales", "double")], transformation_ctx="ChangeSchema_node1795360546775")

# Script generated for node SQL Query
SqlQuery396 = '''
SELECT
 CAST(trim(row_id) AS INT) AS row_id,
 trim(order_id) AS order_id,
 to_date(trim(order_date), 'dd/MM/yyyy') AS order_date,
 to_date(trim(ship_date), 'dd/MM/yyyy') AS ship_date,
 trim(ship_mode) AS ship_mode,
 trim(customer_id) AS customer_id,
 trim(customer_name) AS customer_name,
 trim(segment) AS segment,
 trim(country) AS country,
 trim(city) AS city,
 trim(state) AS state,
 coalesce(nullif(trim(postal_code), ''), 'N/D') AS postal_code,
 trim(region) AS region,
 trim(product_id) AS product_id,
 trim(category) AS category,
 trim(sub_category) AS sub_category,
 trim(product_name) AS product_name,
 CAST(trim(sales) AS DECIMAL(12, 2)) AS sales
FROM myDataSource
 
'''
SQLQuery_node1795360704773 = sparkSqlQuery(glueContext, query = SqlQuery396, mapping = {"myDataSource":ChangeSchema_node1795360546775}, transformation_ctx = "SQLQuery_node1795360704773")

# Script generated for node PostgreSQL
PostgreSQL_node1795360988398 = glueContext.write_dynamic_frame.from_catalog(frame=SQLQuery_node1795360704773, database="superstore_catalog", table_name="superstore_dw_staging_sales", transformation_ctx="PostgreSQL_node1795360988398")

job.commit()